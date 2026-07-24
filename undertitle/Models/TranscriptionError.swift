//
//  TranscriptionError.swift
//  undertitle
//
//  Typed errors surfaced by the transcription pipeline, with user-facing messages.
//

import Foundation

/// Errors that can occur across the pipeline. `errorDescription` is meant to be
/// shown directly to the user.
nonisolated enum TranscriptionError: LocalizedError, Equatable {
    case unsupportedVideoType
    case noAudioTrack
    case unsupportedLocale(String)
    case audioFormatUnavailable
    case modelDownloadFailed
    case readerSetupFailed
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVideoType:
            return "Ese formato de archivo no es un video soportado."
        case .noAudioTrack:
            return "El video no tiene una pista de audio para transcribir."
        case .unsupportedLocale(let id):
            return "El idioma \(id) no está soportado en este dispositivo."
        case .audioFormatUnavailable:
            return "No se encontró un formato de audio compatible para transcribir."
        case .modelDownloadFailed:
            return "No se pudo descargar el modelo de idioma."
        case .readerSetupFailed:
            return "No se pudo leer el audio del video."
        case .transcriptionFailed(let detail):
            return "Falló la transcripción: \(detail)"
        }
    }
}
