//
//  TranscriptionLanguage.swift
//  undertitle
//
//  Languages offered in the picker. Stage 1: English (default) and Spanish.
//

import Foundation

/// A language the user can pick for transcription. Maps to a BCP-47 `Locale`
/// understood by `SpeechTranscriber`.
nonisolated enum TranscriptionLanguage: String, CaseIterable, Identifiable, Sendable {
    case english
    case spanish

    var id: String { rawValue }

    /// Human-readable name shown in the picker.
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }

    /// BCP-47 identifier used to build the `Locale` for `SpeechTranscriber`.
    var localeIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-ES"
        }
    }

    var locale: Locale { Locale(identifier: localeIdentifier) }
}
