//
//  TranscriptSegment.swift
//  undertitle
//
//  A single transcribed chunk of speech with its time range in the audio.
//

import Foundation

/// One unit of transcribed speech, with the time range it covers in the source audio.
/// Each segment maps to one cue in the exported `.srt` file.
nonisolated struct TranscriptSegment: Identifiable, Equatable, Sendable {
    let id: UUID
    let text: String
    /// Start time in the audio, in seconds.
    let start: TimeInterval
    /// End time in the audio, in seconds.
    let end: TimeInterval

    init(id: UUID = UUID(), text: String, start: TimeInterval, end: TimeInterval) {
        self.id = id
        self.text = text
        self.start = start
        self.end = end
    }
}
