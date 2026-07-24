//
//  CueSegmenterTests.swift
//  undertitleTests
//
//  Verifies the cue-splitting logic that keeps subtitles in sync.
//

import Foundation
import Testing
@testable import undertitle

struct CueSegmenterTests {
    let segmenter = CueSegmenter()

    @Test func splitsOnSentenceBoundaries() {
        let chunks = segmenter.chunk("Hola mundo. ¿Cómo estás? Bien!")
        #expect(chunks.count == 3)
        #expect(chunks[0] == "Hola mundo.")
        #expect(chunks[1] == "¿Cómo estás?")
        #expect(chunks[2] == "Bien!")
    }

    @Test func breaksLongSentencesByLength() {
        // One long sentence with no internal punctuation must be split so no
        // chunk exceeds the character ceiling.
        let long = String(repeating: "palabra ", count: 40).trimmingCharacters(in: .whitespaces)
        let chunks = segmenter.chunk(long)
        #expect(chunks.count > 1)
        #expect(chunks.allSatisfy { $0.count <= segmenter.maxCharacters })
    }

    @Test func keepsShortTextAsSingleChunk() {
        let chunks = segmenter.chunk("Una frase corta")
        #expect(chunks == ["Una frase corta"])
    }
}
