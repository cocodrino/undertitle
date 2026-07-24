//
//  SpeechTranscriptionService.swift
//  undertitle
//
//  On-device transcription with Apple SpeechAnalyzer + SpeechTranscriber.
//  Emits a stream of events so the UI layer can stay on the main actor while
//  the heavy work runs on a background task (tasks 4.1–4.5).
//

@preconcurrency import AVFoundation
import Foundation
import Speech

/// Progress and lifecycle events emitted while transcribing.
nonisolated enum TranscriptionEvent: Sendable {
    case preparingModel
    case downloadingModel
    case progress(Double)
    case finished([TranscriptSegment])
}

/// Abstraction over the transcription engine so the view model can be unit-tested
/// against a mock (dependency inversion).
nonisolated protocol Transcribing: Sendable {
    func events(videoURL: URL, language: TranscriptionLanguage) -> AsyncThrowingStream<TranscriptionEvent, Error>
}

/// Transcribes a video's audio on-device. No UI dependencies, no network for
/// transcription itself — the network is only touched to download a missing
/// language model. `nonisolated` so the pipeline runs off the main actor.
nonisolated struct SpeechTranscriptionService: Transcribing {

    private let extractor: AudioExtractor

    init(extractor: AudioExtractor = AudioExtractor()) {
        self.extractor = extractor
    }

    /// Drives the full transcription and reports progress via the returned stream.
    /// The terminal `.finished` event carries the ordered segments.
    func events(videoURL: URL, language: TranscriptionLanguage) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        AsyncThrowingStream { continuation in
            let extractor = self.extractor
            Task {
                do {
                    let segments = try await Self.run(
                        videoURL: videoURL,
                        language: language,
                        extractor: extractor
                    ) { event in
                        continuation.yield(event)
                    }
                    continuation.yield(.finished(segments))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Pipeline

    private static func run(
        videoURL: URL,
        language: TranscriptionLanguage,
        extractor: AudioExtractor,
        emit: @Sendable (TranscriptionEvent) -> Void
    ) async throws -> [TranscriptSegment] {
        let locale = language.locale

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: [.audioTimeRange]
        )

        // 4.2 — verify the locale is supported before doing anything else.
        let supported = await SpeechTranscriber.supportedLocales
        let isSupported = supported.contains { $0.identifier(.bcp47) == locale.identifier(.bcp47) }
        guard isSupported else {
            throw TranscriptionError.unsupportedLocale(locale.identifier)
        }

        // 4.3 — download the language model on first use if it isn't installed.
        let installed = await SpeechTranscriber.installedLocales
        let isInstalled = installed.contains { $0.identifier(.bcp47) == locale.identifier(.bcp47) }
        if !isInstalled {
            emit(.downloadingModel)
            do {
                if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                    try await request.downloadAndInstall()
                }
            } catch {
                throw TranscriptionError.modelDownloadFailed
            }
        }

        emit(.preparingModel)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw TranscriptionError.audioFormatUnavailable
        }

        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()

        // Read results concurrently with feeding audio.
        async let collected = collectSegments(from: transcriber)

        do {
            try await analyzer.start(inputSequence: inputSequence)
        } catch {
            inputBuilder.finish()
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }

        // 3.3 + 4.4 — stream the audio, convert each buffer, feed it, report progress.
        let totalDuration = (try? await extractor.duration(of: videoURL)) ?? 0
        let converter = BufferConverter()
        do {
            for try await timed in extractor.bufferStream(from: videoURL) {
                let converted = try converter.convert(timed.buffer, to: analyzerFormat)
                inputBuilder.yield(AnalyzerInput(buffer: converted))
                if totalDuration > 0 {
                    emit(.progress(min(timed.presentationTime / totalDuration, 1.0)))
                }
            }
        } catch {
            inputBuilder.finish()
            throw error
        }

        inputBuilder.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        emit(.progress(1.0))

        return try await collected
    }

    /// Collects finalized results and re-segments each into properly sized cues
    /// using the per-word timing, so subtitles stay in sync.
    private static func collectSegments(from transcriber: SpeechTranscriber) async throws -> [TranscriptSegment] {
        let segmenter = CueSegmenter()
        var segments: [TranscriptSegment] = []
        for try await result in transcriber.results {
            guard result.isFinal else { continue }
            segments.append(contentsOf: segmenter.segments(from: result.text))
        }
        return segments
    }
}
