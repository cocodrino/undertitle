//
//  ContentView.swift
//  undertitle
//
//  Main screen: drop a video, pick a language, watch progress, save the .srt.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = TranscriptionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            DropView(
                videoName: viewModel.videoName,
                onDrop: { viewModel.videoDropped($0) },
                onInvalid: { /* handled by state below */ }
            )
            .disabled(viewModel.state.isWorking)

            languagePicker

            statusSection

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 460)
        .frame(minHeight: 440)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Undertitle")
                .font(.largeTitle.bold())
            Text("Subtítulos .SRT desde tu video, on-device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var languagePicker: some View {
        HStack {
            Text("Idioma")
                .foregroundStyle(.secondary)
            Picker("Idioma", selection: $viewModel.selectedLanguage) {
                ForEach(TranscriptionLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(viewModel.state.isWorking)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .extractingAudio:
            progressRow(label: "Preparando audio…", value: nil)

        case .preparingModel:
            progressRow(label: "Preparando el modelo de idioma…", value: nil)

        case .downloadingModel:
            progressRow(label: "Descargando modelo de idioma (solo la primera vez)…", value: nil)

        case .transcribing(let progress):
            progressRow(label: "Transcribiendo… \(Int(progress * 100))%", value: progress)

        case .completed(_, let suggestedName):
            VStack(alignment: .leading, spacing: 12) {
                Label("Transcripción lista", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                HStack {
                    Button {
                        viewModel.saveSRT()
                    } label: {
                        Label("Descargar \(suggestedName)", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Otro video") { viewModel.reset() }
                        .buttonStyle(.bordered)
                }
            }

        case .failed(let message):
            VStack(alignment: .leading, spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Button("Reintentar") { viewModel.start() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func progressRow(label: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let value {
                ProgressView(value: value)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
