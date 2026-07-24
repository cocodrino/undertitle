//
//  SRTExporterTests.swift
//  undertitleTests
//
//  Task 8.1 — SRT generation and timestamp formatting.
//

import Testing
@testable import undertitle

struct SRTExporterTests {
    let exporter = SRTExporter()

    @Test func formatsZero() {
        #expect(exporter.timestamp(0) == "00:00:00,000")
    }

    @Test func formatsHoursMinutesSecondsMillis() {
        // 1h 2m 3.456s
        let seconds = 3600.0 + 2 * 60 + 3 + 0.456
        #expect(exporter.timestamp(seconds) == "01:02:03,456")
    }

    @Test func clampsNegativeToZero() {
        #expect(exporter.timestamp(-5) == "00:00:00,000")
    }

    @Test func buildsNumberedCues() {
        let segments = [
            TranscriptSegment(text: "Hello there", start: 1.2, end: 4.5),
            TranscriptSegment(text: "How are you", start: 4.8, end: 7.1),
        ]
        let srt = exporter.srtString(from: segments)
        let expected = """
        1
        00:00:01,200 --> 00:00:04,500
        Hello there

        2
        00:00:04,800 --> 00:00:07,100
        How are you

        """
        #expect(srt == expected)
    }

    @Test func emptySegmentsProduceEmptyString() {
        #expect(exporter.srtString(from: []).isEmpty)
    }
}
