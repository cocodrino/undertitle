//
//  TranscriptionViewModelTests.swift
//  undertitleTests
//
//  Task 8.3 — pipeline state transitions against a mock transcriber.
//

import Foundation
import Testing
@testable import undertitle

/// Replays a scripted sequence of events without touching the Speech framework.
private struct MockTranscriber: Transcribing {
    let scripted: [TranscriptionEvent]

    func events(videoURL: URL, language: TranscriptionLanguage) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        let scripted = self.scripted
        return AsyncThrowingStream { continuation in
            for event in scripted { continuation.yield(event) }
            continuation.finish()
        }
    }
}

private struct FailingTranscriber: Transcribing {
    func events(videoURL: URL, language: TranscriptionLanguage) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        AsyncThrowingStream { $0.finish(throwing: TranscriptionError.noAudioTrack) }
    }
}

@MainActor
struct TranscriptionViewModelTests {

    @Test func completesAndExportsSRT() async {
        let segments = [TranscriptSegment(text: "Hola mundo", start: 0, end: 1.5)]
        let viewModel = TranscriptionViewModel(
            service: MockTranscriber(scripted: [.progress(0.5), .finished(segments)])
        )

        viewModel.videoDropped(URL(fileURLWithPath: "/tmp/clip.mp4"))
        await viewModel.waitUntilDone()

        guard case let .completed(srt, suggestedName) = viewModel.state else {
            Issue.record("Expected .completed, got \(viewModel.state)")
            return
        }
        #expect(srt.contains("Hola mundo"))
        #expect(suggestedName == "clip.srt")
    }

    @Test func surfacesFailureMessage() async {
        let viewModel = TranscriptionViewModel(service: FailingTranscriber())

        viewModel.videoDropped(URL(fileURLWithPath: "/tmp/silent.mp4"))
        await viewModel.waitUntilDone()

        guard case let .failed(message) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(message == TranscriptionError.noAudioTrack.errorDescription)
    }

    @Test func resetReturnsToIdle() async {
        let viewModel = TranscriptionViewModel(
            service: MockTranscriber(scripted: [.finished([])])
        )
        viewModel.videoDropped(URL(fileURLWithPath: "/tmp/clip.mp4"))
        await viewModel.waitUntilDone()

        viewModel.reset()
        #expect(viewModel.state == .idle)
        #expect(viewModel.videoName.isEmpty)
    }
}
