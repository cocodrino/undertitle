<div align="center">

# 🎬 Undertitle

### Drop a video → get perfectly-synced subtitles. On your Mac. Offline. In seconds.

**No cloud. No uploads. No API keys. No subscriptions.**
Your video never leaves your computer.

[![Download](https://img.shields.io/badge/⤓_Download-latest_release-2ea44f?style=for-the-badge)](https://github.com/cocodrino/undertitle/releases/latest)

![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-000000?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-3DA639)
![100% on-device](https://img.shields.io/badge/100%25-on--device-2ea44f)

</div>

---

Undertitle is a dead-simple macOS app that turns any video into an `.srt`
subtitle file — using the same on-device speech engine that powers Siri. Drag a
video in, pick a language, and download subtitles that actually stay in sync.

Because it runs **100% on your Mac**, it's private by design and works on a
plane with no Wi-Fi. No account, no credit card, no "you've used your 10 free
minutes."

```
┌───────────────────────────────────────────────┐
│  Undertitle                                     │
│                                                 │
│   ┌─────────────────────────────────────────┐  │
│   │                                         │  │
│   │        🎬  Drag your video here         │  │
│   │        MP4, MOV, and more               │  │
│   │                                         │  │
│   └─────────────────────────────────────────┘  │
│                                                 │
│   Language:  [ English ▾ ]                      │
│                                                 │
│   Transcribing…  ██████████░░░░░  62%           │
│                                                 │
│   [ ⤓ Download subtitles.srt ]                  │
│                                                 │
└───────────────────────────────────────────────┘
```

## ✨ Why you'll like it

- 🔒 **Truly private** — nothing is uploaded, ever. It works fully offline.
- ⏱️ **Actually in sync** — word-level timing means subtitles land on the words,
  not 30 seconds late.
- 🖱️ **Ridiculously simple** — drag, pick a language, download. That's it.
- 🌎 **English & Spanish** today (more on the way).
- 💸 **Free & open source** — MIT licensed, no strings attached.
- ⚡ **Fast** — powered by Apple's on-device speech models, tuned for Apple Silicon.

## 🚀 Get started

### 1. Install

**Requirements:** a Mac running **macOS 26 (Tahoe)** or later, on **Apple Silicon** (M1 or newer).

#### Option A — Download the app (easiest)

1. Grab the latest **[`Undertitle-macos-arm64.zip`](https://github.com/cocodrino/undertitle/releases/latest)** from Releases.
2. Unzip it and drag **`undertitle.app`** into your **Applications** folder.
3. **First launch only:** right-click the app → **Open** → **Open**.

> That right-click step is needed just once, because the app isn't notarized by
> Apple (it's a free, open-source build). After that it opens normally.

#### Option B — Build from source

Free, and takes about two minutes — you just need [Xcode 26+](https://apps.apple.com/app/xcode/id497799835):

```bash
git clone https://github.com/cocodrino/undertitle.git
cd undertitle
open undertitle.xcodeproj
```
In Xcode, press **▶ Run** (or ⌘R). The app launches. Done.

### 2. Use it

1. **Drag a video** onto the drop area (or the whole window).
2. **Pick the language** spoken in the video — English or Spanish.
3. **Wait** while it transcribes. A progress bar shows how it's going.
4. **Click "Download"** and choose where to save your `.srt` file.

That's the whole flow. Open the `.srt` in your video player (VLC, IINA,
QuickTime with a plugin), or import it into any video editor.

> **First time using a language?** macOS downloads that language's speech model
> once (a quick, one-time step that needs internet). Every transcription after
> that runs completely offline.

## 🧠 How it works

```
🎬 Video
  │  AVFoundation reads the audio track (streaming — even hours-long videos)
  ▼
🔊 Audio
  │  Apple SpeechAnalyzer + SpeechTranscriber, on-device
  ▼
📝 Text + a timestamp for every word
  │  CueSegmenter splits it into short, readable, perfectly-timed cues
  ▼
📄 subtitles.srt
```

The speech engine returns text in big chunks, so Undertitle re-cuts it using the
per-word timing into subtitle-sized lines (broken at sentence ends, capped at
~6 seconds each). That's the difference between subtitles that drift and
subtitles that hit every line on time.

## 📦 Sharing a build with a friend (optional)

Want to hand the app to someone without Xcode? In Xcode: **Product → Archive →
Distribute App → Custom → Copy App**, then zip the resulting `Undertitle.app`.

> Because the app isn't notarized by Apple, the first time they open it they'll
> need to **right-click the app → Open → Open** to get past Gatekeeper. This is
> normal for open-source apps you build yourself.

## 🏗️ Architecture

<details>
<summary>Clean, layered, and fully testable — click to expand</summary>

<br>

| Layer | Pieces | Responsibility |
|-------|--------|----------------|
| **Models** | `TranscriptSegment`, `TranscriptionLanguage`, `TranscriptionState`, `TranscriptionError` | Plain data + the single state that drives the UI |
| **Services** | `AudioExtractor`, `BufferConverter`, `SpeechTranscriptionService`, `CueSegmenter`, `SRTExporter` | The pipeline — each piece independent and unit-tested |
| **ViewModel** | `TranscriptionViewModel` (`@Observable`) | Orchestrates the pipeline, publishes state |
| **Views** | `DropView`, `ContentView` | SwiftUI, renders entirely from state |

Transcription sits behind a `Transcribing` protocol, so the view model is tested
against a mock without ever touching the Speech framework. The heavy audio work
is marked `nonisolated` so it runs off the main actor and never freezes the UI.

Run the tests:
```bash
xcodebuild -project undertitle.xcodeproj -scheme undertitle -destination 'platform=macOS' test
```

</details>

## 🗺️ Roadmap

- [ ] Automatic language detection
- [ ] More languages beyond English & Spanish
- [ ] Optional AI pass to polish punctuation and proper nouns
- [ ] In-app subtitle preview & editing
- [ ] A notarized release (double-click to open, no right-click needed)
- [ ] Universal binary (Intel + Apple Silicon)

## 🤝 Contributing

Issues and pull requests are welcome! Whether it's a bug, a new language, or a UI
tweak — open an issue to start the conversation.

## 📄 License

[MIT](LICENSE) © 2026 cocodrino

---

<div align="center">

*Built with Apple's on-device Speech framework. Not affiliated with Apple.*

**If Undertitle saved you time, consider giving it a ⭐ — it helps other people find it.**

</div>
