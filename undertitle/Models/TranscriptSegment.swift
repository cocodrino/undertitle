//
//  TranscriptSegment.swift
//  undertitle
//
//  A single transcribed chunk of speech with its time range in the audio.
//

import Foundation

/// One unit of transcribed speech, with the time range it covers in the source audio.
/// Each segment maps to one cue in the exported `.srt` file.
public nonisolated struct TranscriptSegment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    /// Start time in the audio, in seconds.
    public let start: TimeInterval
    /// End time in the audio, in seconds.
    public let end: TimeInterval

    public init(id: UUID = UUID(), text: String, start: TimeInterval, end: TimeInterval) {
        self.id = id
        self.text = text
        self.start = start
        self.end = end
    }
}
