//
//  TranscriptionViewModel.swift
//  undertitle
//
//  Orchestrates the pipeline (extract → transcribe → export) and publishes a
//  single state the UI renders from (tasks 6.1–6.3).
//

import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class TranscriptionViewModel {

    /// Single source of truth for the UI.
    private(set) var state: TranscriptionState = .idle

    /// Language chosen in the picker. Defaults to English (stage 1 requirement).
    var selectedLanguage: TranscriptionLanguage = .english

    private(set) var videoName: String = ""
    private var videoURL: URL?

    private let service: any Transcribing
    private let exporter: SRTExporter
    private var work: Task<Void, Never>?

    init(service: any Transcribing = SpeechTranscriptionService(),
         exporter: SRTExporter = SRTExporter()) {
        self.service = service
        self.exporter = exporter
    }

    /// Awaits the in-flight transcription. Test seam — production UI is driven by `state`.
    func waitUntilDone() async {
        await work?.value
    }

    // MARK: - Intent

    /// Called when a valid video is dropped. Kicks off transcription immediately
    /// using the currently selected language.
    func videoDropped(_ url: URL) {
        videoURL = url
        videoName = url.deletingPathExtension().lastPathComponent
        start()
    }

    /// Restart with the current video (e.g. after changing language or an error).
    func start() {
        guard let videoURL else { return }
        work?.cancel()
        state = .extractingAudio

        let language = selectedLanguage
        let service = self.service
        let exporter = self.exporter

        work = Task { [weak self] in
            do {
                var segments: [TranscriptSegment] = []
                for try await event in service.events(videoURL: videoURL, language: language) {
                    switch event {
                    case .downloadingModel:
                        self?.state = .downloadingModel
                    case .preparingModel:
                        self?.state = .preparingModel
                    case .progress(let value):
                        self?.state = .transcribing(progress: value)
                    case .finished(let result):
                        segments = result
                    }
                }
                guard !Task.isCancelled else { return }
                let srt = exporter.srtString(from: segments)
                self?.state = .completed(srt: srt, suggestedName: (self?.videoName ?? "subtitles") + ".srt")
            } catch is CancellationError {
                // Intentionally ignored — a newer run replaced this one.
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                self?.state = .failed(message: message)
            }
        }
    }

    func reset() {
        work?.cancel()
        videoURL = nil
        videoName = ""
        state = .idle
    }

    /// Presents a save panel and writes the generated `.srt` to the chosen path.
    func saveSRT() {
        guard case let .completed(srt, suggestedName) = state else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        if let srtType = UTType(filenameExtension: "srt") {
            panel.allowedContentTypes = [srtType]
        }
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try srt.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            state = .failed(message: "No se pudo guardar el archivo: \(error.localizedDescription)")
        }
    }
}
