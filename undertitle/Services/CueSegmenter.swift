//
//  CueSegmenter.swift
//  undertitle
//
//  Breaks a transcriber result into properly sized subtitle cues. The
//  SpeechTranscriber finalizes speech in large blocks (tens of seconds), which
//  is useless for syncing. This re-segments using the per-word `audioTimeRange`
//  timing, falling back to a proportional split when only coarse timing exists.
//

import CoreMedia
import Foundation

nonisolated struct CueSegmenter {
    /// Hard ceiling on how long a single cue may last (subtitle standard ~1–6s).
    var maxDuration: TimeInterval = 6
    /// Hard ceiling on characters per cue (~2 lines of 42 chars).
    var maxCharacters: Int = 84
    /// A silence longer than this between words forces a cue break.
    var maxGap: TimeInterval = 0.8

    private struct TimedToken {
        let text: String
        let start: TimeInterval
        let end: TimeInterval
    }

    /// Splits a result's attributed text into one or more cues.
    func segments(from text: AttributedString) -> [TranscriptSegment] {
        let tokens = timedTokens(from: text)
        if tokens.count > 1 {
            return segments(fromTokens: tokens)
        }
        // Fallback: only coarse (or no) per-word timing — split text by sentences
        // and distribute the overall time range proportionally by length.
        guard let range = overallRange(of: text) else { return [] }
        let full = String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !full.isEmpty else { return [] }
        return proportionalSegments(text: full, start: range.start, end: range.end)
    }

    // MARK: - Word-timed path

    private func timedTokens(from text: AttributedString) -> [TimedToken] {
        var tokens: [TimedToken] = []
        for run in text.runs {
            guard let range = run.audioTimeRange else { continue }
            let piece = String(text[run.range].characters)
            guard !piece.isEmpty else { continue }
            tokens.append(TimedToken(text: piece, start: range.start.seconds, end: range.end.seconds))
        }
        return tokens
    }

    private func segments(fromTokens tokens: [TimedToken]) -> [TranscriptSegment] {
        var result: [TranscriptSegment] = []
        var buffer = ""
        var start: TimeInterval?
        var end: TimeInterval = 0
        var lastEnd: TimeInterval?

        func flush() {
            let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if let start, !trimmed.isEmpty {
                result.append(TranscriptSegment(text: trimmed, start: start, end: end))
            }
            buffer = ""
            start = nil
        }

        for token in tokens {
            // A long pause is a natural cue boundary.
            if let lastEnd, start != nil, token.start - lastEnd > maxGap {
                flush()
            }
            if start == nil { start = token.start }
            buffer += token.text
            end = token.end
            lastEnd = token.end

            let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            let endsSentence = trimmed.last.map { ".!?".contains($0) } ?? false
            let tooLong = end - (start ?? end) >= maxDuration
            let tooMany = trimmed.count >= maxCharacters
            if endsSentence || tooLong || tooMany {
                flush()
            }
        }
        flush()
        return result
    }

    // MARK: - Proportional fallback

    private func proportionalSegments(text: String, start: TimeInterval, end: TimeInterval) -> [TranscriptSegment] {
        let chunks = chunk(text)
        let totalChars = max(1, chunks.reduce(0) { $0 + $1.count })
        let totalDuration = max(0.001, end - start)

        var cursor = start
        var result: [TranscriptSegment] = []
        for piece in chunks {
            let trimmed = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let fraction = Double(piece.count) / Double(totalChars)
            let segEnd = min(end, cursor + totalDuration * fraction)
            result.append(TranscriptSegment(text: trimmed, start: cursor, end: segEnd))
            cursor = segEnd
        }
        return result
    }

    /// Splits text into sentence-ish chunks, then breaks any chunk longer than
    /// `maxCharacters` at word boundaries.
    func chunk(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if ".!?".contains(character) {
                sentences.append(current)
                current = ""
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(current)
        }

        return sentences.flatMap { splitByLength($0) }
    }

    private func splitByLength(_ sentence: String) -> [String] {
        let trimmed = sentence.trimmingCharacters(in: .whitespaces)
        guard trimmed.count > maxCharacters else { return trimmed.isEmpty ? [] : [trimmed] }

        var chunks: [String] = []
        var current = ""
        for word in trimmed.split(separator: " ") {
            let candidate = current.isEmpty ? String(word) : current + " " + word
            if candidate.count > maxCharacters, !current.isEmpty {
                chunks.append(current)
                current = String(word)
            } else {
                current = candidate
            }
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    private func overallRange(of text: AttributedString) -> (start: TimeInterval, end: TimeInterval)? {
        var start: TimeInterval?
        var end: TimeInterval?
        for run in text.runs {
            guard let range = run.audioTimeRange else { continue }
            let runStart = range.start.seconds
            let runEnd = range.end.seconds
            if start == nil || runStart < start! { start = runStart }
            if end == nil || runEnd > end! { end = runEnd }
        }
        guard let start, let end else { return nil }
        return (start, end)
    }
}
