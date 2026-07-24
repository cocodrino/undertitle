//
//  DropView.swift
//  undertitle
//
//  Drag & drop target for a video file, with visual feedback (task 7.1).
//

import SwiftUI
import UniformTypeIdentifiers

struct DropView: View {
    let videoName: String
    let onDrop: (URL) -> Void
    let onInvalid: () -> Void

    @State private var isTargeted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                style: StrokeStyle(lineWidth: 2, dash: [8])
            )
            .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.04))
            )
            .frame(height: 200)
            .overlay { content }
            .animation(.easeInOut(duration: 0.15), value: isTargeted)
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                if Self.isAudiovisual(url) {
                    onDrop(url)
                    return true
                }
                onInvalid()
                return false
            } isTargeted: { isTargeted = $0 }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 10) {
            Image(systemName: videoName.isEmpty ? "film" : "film.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            if videoName.isEmpty {
                Text("Arrastrá tu video aquí")
                    .font(.headline)
                Text("MP4, MOV y otros formatos de video")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(videoName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding()
    }

    /// True when the dropped file is audiovisual content we can read with AVFoundation.
    static func isAudiovisual(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .audiovisualContent)
            || type.conforms(to: .movie)
            || type.conforms(to: .video)
    }
}
