## Why

Generar subtítulos para un video hoy obliga a usar servicios en la nube (privacidad, costo, dependencia de internet) o herramientas técnicas de línea de comandos. Undertitle resuelve esto con una app de escritorio simple: arrastrás un video, elegís el idioma, y obtenés un archivo `.SRT` con timestamps — todo on-device, offline y gratis, aprovechando la API nativa de transcripción de macOS 26.

## What Changes

- Nueva app SwiftUI para macOS 26 (Tahoe) — proyecto desde cero.
- Área de **drag & drop** donde el usuario suelta un archivo de video local.
- **Dropdown de idioma** debajo del área de drop, con inglés (`en-US`) por defecto y español (`es-ES`) seleccionable.
- **Extracción de audio** del video mediante AVFoundation.
- **Transcripción on-device** con Apple `SpeechAnalyzer` + `SpeechTranscriber`, usando el locale elegido, obteniendo texto + timestamps vía `audioTimeRange`.
- **Barra de progreso** que refleja el avance de la transcripción.
- **Generación y guardado del archivo `.SRT`** con segmentos numerados y timestamps en formato `HH:MM:SS,mmm`.
- Manejo de la **descarga del modelo de idioma** (`AssetInventory`) la primera vez que se usa un locale no presente en el dispositivo.

Fuera de alcance (etapa 2): auto-detección de idioma, idiomas adicionales, edición de subtítulos, post-procesado con LLM.

## Capabilities

### New Capabilities
- `video-drop`: recepción de un video por drag & drop, validación del archivo y selección de idioma de transcripción.
- `audio-extraction`: extracción de la pista de audio del video a un formato apto para transcripción.
- `speech-transcription`: transcripción on-device del audio con Apple SpeechAnalyzer, incluyendo gestión de locales soportados y descarga de modelos de idioma.
- `srt-export`: conversión de los segmentos transcritos (texto + timestamps) a un archivo `.SRT` válido y su guardado en disco.
- `transcription-progress`: reporte del progreso del proceso de transcripción hacia la UI.

### Modified Capabilities
<!-- Ninguna: proyecto nuevo, no hay specs existentes. -->

## Impact

- **Plataforma**: macOS 26 (Tahoe) como mínimo — `SpeechAnalyzer`/`SpeechTranscriber` no existen en versiones anteriores.
- **Frameworks**: SwiftUI (UI), AVFoundation (extracción de audio), Speech (transcripción + `AssetInventory`), UniformTypeIdentifiers (tipos de archivo en drag & drop).
- **Dependencias externas**: ninguna — todo nativo de Apple, sin paquetes de terceros.
- **Permisos / entitlements**: acceso a archivos seleccionados por el usuario (sandbox), posible descarga de assets de idioma.
- **Red**: solo para descargar el modelo de idioma la primera vez; la transcripción es offline.
