//
//  BufferConverter.swift
//  undertitle
//
//  Converts decoded PCM buffers into the format SpeechAnalyzer asks for.
//

@preconcurrency import AVFoundation
import Foundation
import os

/// Wraps `AVAudioConverter` to turn buffers read from the video into the
/// `analyzerFormat` that `SpeechAnalyzer` reports as best.
nonisolated final class BufferConverter {
    enum Failure: Error {
        case failedToCreateConverter
        case failedToCreateConversionBuffer
        case conversionFailed(NSError?)
    }

    private var converter: AVAudioConverter?

    func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        guard inputFormat != format else { return buffer }

        if converter == nil || converter?.outputFormat != format {
            converter = AVAudioConverter(from: inputFormat, to: format)
            // Avoid timestamp drift on the first samples.
            converter?.primeMethod = .none
        }

        guard let converter else { throw Failure.failedToCreateConverter }

        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledFrames = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledFrames.rounded(.up))

        guard let output = AVAudioPCMBuffer(pcmFormat: converter.outputFormat,
                                            frameCapacity: frameCapacity) else {
            throw Failure.failedToCreateConversionBuffer
        }

        var nsError: NSError?
        // The input buffer is offered exactly once; the flag lives behind a lock
        // so the `@Sendable` fill closure never captures a mutable var.
        let consumed = OSAllocatedUnfairLock(initialState: false)
        let status = converter.convert(to: output, error: &nsError) { _, inputStatus in
            let wasConsumed = consumed.withLock { flag in
                let previous = flag
                flag = true
                return previous
            }
            inputStatus.pointee = wasConsumed ? .noDataNow : .haveData
            return wasConsumed ? nil : buffer
        }

        guard status != .error else { throw Failure.conversionFailed(nsError) }
        return output
    }
}
