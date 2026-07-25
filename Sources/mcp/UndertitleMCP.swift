//
//  UndertitleMCP.swift
//  undertitle-mcp
//
//  An MCP server exposing Undertitle's on-device transcription as a tool,
//  so AI agents can turn a local video into .srt subtitles.
//

import Foundation
import MCP
import UndertitleKit

@main
struct UndertitleMCP {
    static func main() async throws {
        let server = Server(
            name: "undertitle",
            version: "0.2.1",
            capabilities: .init(tools: .init(listChanged: false))
        )

        // Advertise the single tool we expose.
        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: [
                Tool(
                    name: "transcribe_video",
                    description: """
                    Transcribe a local video file into SubRip (.srt) subtitles, fully on-device \
                    (Apple SpeechAnalyzer). Returns the .srt text with per-cue timestamps. \
                    Supports English and Spanish.
                    """,
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "path": .object([
                                "type": .string("string"),
                                "description": .string("Absolute path to the local video file."),
                            ]),
                            "language": .object([
                                "type": .string("string"),
                                "description": .string("Spoken language: 'en' or 'es'. Defaults to 'en'."),
                                "enum": .array([.string("en"), .string("es")]),
                            ]),
                        ]),
                        "required": .array([.string("path")]),
                    ])
                )
            ])
        }

        // Handle tool calls.
        await server.withMethodHandler(CallTool.self) { params in
            guard params.name == "transcribe_video" else {
                return result("Unknown tool: \(params.name)", isError: true)
            }
            guard let path = params.arguments?["path"]?.stringValue else {
                return result("Missing required 'path' argument.", isError: true)
            }

            let langRaw = params.arguments?["language"]?.stringValue ?? "en"
            let language: TranscriptionLanguage
            switch langRaw.lowercased() {
            case "en", "english": language = .english
            case "es", "spanish", "español", "espanol": language = .spanish
            default:
                return result("Unsupported language '\(langRaw)'. Use 'en' or 'es'.", isError: true)
            }

            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return result("File not found: \(path)", isError: true)
            }

            do {
                let service = SpeechTranscriptionService()
                var segments: [TranscriptSegment] = []
                for try await event in service.events(videoURL: url, language: language) {
                    if case .finished(let cues) = event { segments = cues }
                }
                let srt = SRTExporter().srtString(from: segments)
                return result(srt)
            } catch {
                return result("Transcription failed: \(error.localizedDescription)", isError: true)
            }
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    /// Builds a `CallTool` result carrying a single text block.
    private static func result(_ text: String, isError: Bool = false) -> CallTool.Result {
        .init(content: [.text(text: text, annotations: nil, _meta: nil)], isError: isError)
    }
}
