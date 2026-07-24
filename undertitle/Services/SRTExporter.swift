//
//  SRTExporter.swift
//  undertitle
//
//  Turns transcript segments into a valid .srt document (tasks 5.1–5.2).
//

import Foundation

/// Formats `TranscriptSegment`s as SubRip (`.srt`) text. Pure and synchronous,
/// which makes it trivial to unit-test.
nonisolated struct SRTExporter {

    /// Builds the full `.srt` document. Each segment becomes one numbered cue.
    func srtString(from segments: [TranscriptSegment]) -> String {
        segments.enumerated().map { index, segment in
            let cueNumber = index + 1
            let start = timestamp(segment.start)
            let end = timestamp(segment.end)
            return "\(cueNumber)\n\(start) --> \(end)\n\(segment.text)\n"
        }
        .joined(separator: "\n")
    }

    /// Formats a time in seconds as `HH:MM:SS,mmm` (SubRip uses a comma before
    /// the milliseconds).
    func timestamp(_ seconds: TimeInterval) -> String {
        let clamped = max(0, seconds)
        let totalMilliseconds = Int((clamped * 1000).rounded())
        let milliseconds = totalMilliseconds % 1000
        let totalSeconds = totalMilliseconds / 1000
        let secs = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, milliseconds)
    }
}
