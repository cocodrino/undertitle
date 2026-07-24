//
//  AudioExtractorTests.swift
//  undertitleTests
//
//  Task 8.2 — audio extraction happy path and the no-audio error path.
//

@preconcurrency import AVFoundation
import Foundation
import Testing
@testable import undertitle

struct AudioExtractorTests {
    let extractor = AudioExtractor()

    @Test func reportsDurationAndStreamsBuffers() async throws {
        let url = try Self.makeSilentAudioFile(seconds: 1)
        defer { try? FileManager.default.removeItem(at: url) }

        let duration = try await extractor.duration(of: url)
        #expect(duration > 0.5)

        var bufferCount = 0
        for try await _ in extractor.bufferStream(from: url) {
            bufferCount += 1
            if bufferCount >= 1 { break }
        }
        #expect(bufferCount >= 1)
    }

    @Test func throwsWhenNoAudioTrack() async throws {
        // A plain text file has no audio track; the stream must fail.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).txt")
        try "not a video".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        await #expect(throws: (any Error).self) {
            for try await _ in extractor.bufferStream(from: url) {}
        }
    }

    /// Writes a short silent CAF file we can read back as an AV asset with an audio track.
    private static func makeSilentAudioFile(seconds: Double) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).caf")
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else {
            throw TranscriptionError.audioFormatUnavailable
        }
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let frames = AVAudioFrameCount(44_100 * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            throw TranscriptionError.audioFormatUnavailable
        }
        buffer.frameLength = frames // silence
        try file.write(from: buffer)
        return url
    }
}
