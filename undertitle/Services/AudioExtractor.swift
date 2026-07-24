//
//  AudioExtractor.swift
//  undertitle
//
//  Reads the audio track out of a video via AVAssetReader, streaming PCM
//  buffers so we never load the whole file into memory (task 3.3).
//

@preconcurrency import AVFoundation
import Foundation

/// A decoded audio buffer paired with its presentation time, used both to feed
/// the transcriber and to report progress against the total duration.
nonisolated struct TimedAudioBuffer: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
    let presentationTime: TimeInterval
}

/// Extracts the audio track from a video file as a stream of PCM buffers.
/// Pure of any UI dependency so it can be unit-tested in isolation.
/// `nonisolated` so the heavy read loop runs off the main actor.
nonisolated struct AudioExtractor {

    /// Total duration of the asset in seconds. Used to compute progress.
    func duration(of url: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }

    /// Streams the asset's audio as linear-PCM buffers in presentation order.
    /// Throws `.noAudioTrack` if the video has no audio, `.readerSetupFailed`
    /// if the reader cannot be created.
    func bufferStream(from url: URL) -> AsyncThrowingStream<TimedAudioBuffer, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let asset = AVURLAsset(url: url)
                    guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
                        continuation.finish(throwing: TranscriptionError.noAudioTrack)
                        return
                    }

                    let reader: AVAssetReader
                    do {
                        reader = try AVAssetReader(asset: asset)
                    } catch {
                        continuation.finish(throwing: TranscriptionError.readerSetupFailed)
                        return
                    }

                    // Ask for decompressed linear PCM; the format description on
                    // each sample buffer tells us the concrete layout.
                    let outputSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM
                    ]
                    let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
                    output.alwaysCopiesSampleData = false

                    guard reader.canAdd(output) else {
                        continuation.finish(throwing: TranscriptionError.readerSetupFailed)
                        return
                    }
                    reader.add(output)

                    guard reader.startReading() else {
                        continuation.finish(throwing: reader.error ?? TranscriptionError.readerSetupFailed)
                        return
                    }

                    while reader.status == .reading {
                        guard let sample = output.copyNextSampleBuffer() else { break }
                        let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
                        if let pcm = Self.pcmBuffer(from: sample) {
                            continuation.yield(TimedAudioBuffer(buffer: pcm, presentationTime: time))
                        }
                        CMSampleBufferInvalidate(sample)
                    }

                    if reader.status == .failed {
                        continuation.finish(throwing: reader.error ?? TranscriptionError.readerSetupFailed)
                    } else {
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Builds an `AVAudioPCMBuffer` from a decoded audio `CMSampleBuffer`.
    private static func pcmBuffer(from sample: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sample),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        else { return nil }

        let format = AVAudioFormat(streamDescription: asbd)
        guard let format else { return nil }

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sample))
        guard frameCount > 0,
              let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return nil }

        pcm.frameLength = frameCount
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sample,
            at: 0,
            frameCount: Int32(frameCount),
            into: pcm.mutableAudioBufferList
        )
        return status == noErr ? pcm : nil
    }
}
