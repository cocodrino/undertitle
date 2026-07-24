# Undertitle

**Drop a video, get perfectly-synced `.srt` subtitles. 100% on-device, private, and offline — powered by Apple's on-device speech engine. English & Spanish.**

Undertitle is a tiny, focused macOS app: drag a video onto the window, pick a
language, and download a subtitle file with accurate, word-level timing. Your
video never leaves your Mac — there is no cloud, no upload, no API key.

---

## Why

Generating subtitles usually means uploading your footage to a cloud service
(privacy, cost, an internet connection) or wrangling command-line tools.
Undertitle does it locally using the same on-device speech models macOS ships
with, so it is **fast, free, and private by design**.

## Features

- 🎬 **Drag & drop** any video file
- 🗣️ **On-device transcription** via Apple's `SpeechAnalyzer` / `SpeechTranscriber`
- ⏱️ **Word-level timing** → subtitles that actually stay in sync
- 🌎 **English & Spanish** (more languages planned)
- 📊 **Live progress** while it works
- 📄 **Standard `.srt` export** you can drop into any video player or editor
- 🔒 **Offline & private** — nothing is uploaded, ever

## How it works

```
🎬 Video
  │  AVFoundation (AVAssetReader, streaming)
  ▼
🔊 Audio buffers
  │  Apple SpeechAnalyzer + SpeechTranscriber (on-device)
  ▼
📝 Text + per-word timestamps (audioTimeRange)
  │  CueSegmenter — split into properly sized, synced cues
  ▼
📄 .srt file
```

The transcription engine returns speech in large finalized blocks, so Undertitle
re-segments them using the per-word timing into short cues (split on sentence
boundaries, capped at ~6s / ~84 characters) — the difference between subtitles
that drift and subtitles that land.

## Requirements

- **macOS 26 (Tahoe) or later** — `SpeechAnalyzer` / `SpeechTranscriber` are not
  available on earlier versions.
- **Xcode 26+** to build from source.

> On first use of a language, macOS downloads its speech model on-device (a
> one-time step). After that, transcription runs fully offline.

## Build & run

```bash
git clone https://github.com/<your-username>/undertitle.git
cd undertitle
open undertitle.xcodeproj
```

Then press **⌘R** in Xcode. Or from the command line:

```bash
xcodebuild -project undertitle.xcodeproj -scheme undertitle -destination 'platform=macOS' build
```

## Architecture

Clean, layered, and testable — no UI logic mixed into the transcription pipeline:

| Layer | Type | Responsibility |
|-------|------|----------------|
| **Models** | `TranscriptSegment`, `TranscriptionLanguage`, `TranscriptionState`, `TranscriptionError` | Plain data + the single state that drives the UI |
| **Services** | `AudioExtractor`, `BufferConverter`, `SpeechTranscriptionService`, `CueSegmenter`, `SRTExporter` | The pipeline — each piece independent and unit-tested |
| **ViewModel** | `TranscriptionViewModel` (`@Observable`) | Orchestrates the pipeline, publishes state |
| **Views** | `DropView`, `ContentView` | SwiftUI, renders entirely from state |

Transcription is exposed through a `Transcribing` protocol, so the view model is
tested against a mock without touching the Speech framework.

## Tests

```bash
xcodebuild -project undertitle.xcodeproj -scheme undertitle -destination 'platform=macOS' test
```

Covers SRT formatting, audio extraction, the cue segmenter, and the view model's
state transitions (Swift Testing).

## Roadmap

- [ ] Automatic language detection
- [ ] More languages beyond English & Spanish
- [ ] Optional LLM pass to polish punctuation and proper nouns
- [ ] In-app subtitle preview & editing

## License

[MIT](LICENSE) © 2026 Carlos Laguna Medina

---

*Built with Apple's on-device Speech framework. Undertitle is not affiliated with Apple.*
