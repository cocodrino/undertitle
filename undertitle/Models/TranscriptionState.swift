//
//  TranscriptionState.swift
//  undertitle
//
//  Single source of truth for where the pipeline is. Drives the whole UI.
//

import Foundation

/// The current stage of the transcription pipeline. The UI renders entirely
/// from this value, so there is one predictable, debuggable source of truth.
enum TranscriptionState: Equatable {
    case idle
    case extractingAudio
    case preparingModel
    case downloadingModel
    case transcribing(progress: Double)
    case completed(srt: String, suggestedName: String)
    case failed(message: String)

    var isWorking: Bool {
        switch self {
        case .extractingAudio, .preparingModel, .downloadingModel, .transcribing:
            return true
        default:
            return false
        }
    }
}
