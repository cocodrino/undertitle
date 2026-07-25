//
//  main.swift
//  undertitle-cli
//
//  Command-line front-end for the Undertitle transcription pipeline.
//

import ArgumentParser
import Foundation
import UndertitleKit

@main
struct UndertitleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "undertitle",
        abstract: "Generate .srt subtitles from a video, fully on-device.",
        version: "0.1.0",
        subcommands: [Transcribe.self],
        defaultSubcommand: Transcribe.self
    )
}

struct Transcribe: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Transcribe a video's speech into an .srt subtitle file."
    )

    @Argument(help: "Path to the video file.")
    var video: String

    @Option(name: [.short, .long], help: "Spoken language: 'en' or 'es'.")
    var language: String = "en"

    @Option(name: [.short, .long], help: "Output .srt path. Defaults to <video>.srt. Use '-' for stdout.")
    var output: String?

    @Flag(name: .long, help: "Suppress progress messages on stderr.")
    var quiet = false

    func run() async throws {
        let lang = try parseLanguage(language)

        let videoURL = URL(fileURLWithPath: video)
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw ValidationError("File not found: \(video)")
        }

        let service = SpeechTranscriptionService()
        var segments: [TranscriptSegment] = []

        for try await event in service.events(videoURL: videoURL, language: lang) {
            switch event {
            case .downloadingModel:
                log("Downloading language model (first use of this language)…")
            case .preparingModel:
                log("Preparing…")
            case .progress(let value):
                logProgress("Transcribing… \(Int(value * 100))%")
            case .finished(let result):
                segments = result
            }
        }
        if !quiet { FileHandle.standardError.write(Data("\n".utf8)) }

        let srt = SRTExporter().srtString(from: segments)

        if output == "-" {
            print(srt)
        } else {
            let outURL = output.map { URL(fileURLWithPath: $0) }
                ?? videoURL.deletingPathExtension().appendingPathExtension("srt")
            try srt.write(to: outURL, atomically: true, encoding: .utf8)
            log("Saved \(outURL.path) — \(segments.count) cues")
        }
    }

    private func parseLanguage(_ raw: String) throws -> TranscriptionLanguage {
        switch raw.lowercased() {
        case "en", "english": return .english
        case "es", "spanish", "español", "espanol": return .spanish
        default:
            throw ValidationError("Unsupported language '\(raw)'. Use 'en' or 'es'.")
        }
    }

    private func log(_ message: String) {
        guard !quiet else { return }
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }

    private func logProgress(_ message: String) {
        // Only draw the in-place `\r` progress line on an interactive terminal;
        // when piped/redirected it would spam one line per update.
        guard !quiet, isatty(FileHandle.standardError.fileDescriptor) != 0 else { return }
        FileHandle.standardError.write(Data(("\r" + message).utf8))
    }
}
