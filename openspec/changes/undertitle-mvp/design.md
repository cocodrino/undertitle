## Context

Undertitle es una app SwiftUI nueva para macOS 26 (Tahoe). El objetivo del MVP es transformar un video local en un archivo `.SRT` con subtítulos sincronizados, on-device y offline. La decisión de motor ASR ya está tomada y verificada: **Apple `SpeechAnalyzer` + `SpeechTranscriber`**, descartando Gemma 4 (no produce timestamps, tope de 30s por inferencia) y Whisper (resultados insatisfactorios reportados por el usuario, y 2.2× más lento que la API nativa).

Restricciones:
- `SpeechAnalyzer`/`SpeechTranscriber` solo existen en macOS 26+.
- La API exige un `Locale` explícito; no detecta idioma automáticamente.
- Los modelos de idioma se descargan on-demand vía `AssetInventory`, no vienen todos preinstalados.

## Goals / Non-Goals

**Goals:**
- Pipeline claro y testeable: drop → extracción de audio → transcripción → SRT.
- Arquitectura modular y desacoplada de la UI (lógica de transcripción sin dependencias de SwiftUI), para poder testear y reusar.
- Manejo explícito de los estados del proceso (idle, descargando modelo, transcribiendo, listo, error) reflejados en la UI.
- Soporte inglés (`en-US`) y español (`es-ES`) en etapa 1.

**Non-Goals:**
- Auto-detección de idioma (etapa 2).
- Edición de subtítulos en la app.
- Post-procesado con LLM (Gemma como capa de pulido — etapa 2).
- Soporte de macOS anterior a 26.
- Transcripción en streaming/tiempo real desde micrófono (solo archivos).

## Decisions

### 1. Motor ASR: Apple SpeechAnalyzer + SpeechTranscriber
**Por qué**: nativo, on-device, timestamps vía `audioTimeRange`, sin dependencias externas, más rápido que Whisper. **Alternativas**: Whisper/WhisperKit (más lento, peor resultado para el usuario), Gemma 4 (sin timestamps, chunking a 30s), Parakeet V3/MLX (fricción de bundle). Ver memoria `architecture/asr-engine`.

### 2. Arquitectura por capas
```
┌─────────────────── UI (SwiftUI) ───────────────────┐
│  DropView · LanguagePicker · ProgressView · Export   │
└───────────────────────┬─────────────────────────────┘
                        │  observa estado (@Observable)
┌───────────────────────▼─────────────────────────────┐
│             TranscriptionViewModel                   │
│   orquesta el pipeline, expone estado + progreso     │
└───────────────────────┬─────────────────────────────┘
                        │
   ┌────────────────────┼────────────────────┐
   ▼                    ▼                     ▼
AudioExtractor   SpeechTranscription      SRTExporter
(AVFoundation)   Service (Speech)         (formateo SRT)
```
La lógica de negocio (extracción, transcripción, exportación) vive en servicios puros sin SwiftUI; el `ViewModel` orquesta y publica estado con `@Observable`. **Por qué**: testabilidad, separación de responsabilidades, código mantenible de producción. **Alternativa descartada**: meter todo en las vistas SwiftUI → no testeable, no reusable.

### 3. Extracción de audio con AVFoundation
Usar `AVAssetExportSession`/`AVAssetReader` para extraer la pista de audio del video a un formato PCM/lineal apto para `SpeechAnalyzer`. **Por qué**: nativo, sin ffmpeg ni binarios externos.

### 4. Gestión de locales y descarga de modelos
Antes de transcribir: (a) verificar que el locale elegido esté en `SpeechTranscriber.supportedLocales`; (b) si el asset no está instalado, solicitar descarga vía `AssetInventory` y reflejar ese estado en la UI ("Descargando modelo de idioma…"). **Por qué**: evita el fallo silencioso de la primera transcripción.

### 5. Generación del SRT
Mapear cada segmento transcrito (texto + `audioTimeRange` con inicio/fin) a un bloque SRT: índice incremental, timestamps `HH:MM:SS,mmm`, texto. **Por qué**: formato estándar, ampliamente compatible.

### 6. Modelo de estados del proceso
Una enum de estado único (`idle → extractingAudio → preparingModel → transcribing(progress) → completed(srtURL) → failed(error)`) dirige toda la UI. **Por qué**: UI predecible y debuggeable, un solo origen de verdad.

## Risks / Trade-offs

- **Solo macOS 26+** → Mitigación: es un requisito aceptado del producto; documentar el mínimo claramente.
- **Descarga de modelo en la primera corrida puede confundir al usuario** → Mitigación: estado explícito en UI + barra/indicador de descarga separado del de transcripción.
- **Precisión de timestamps depende de la API de Apple** → Mitigación: usar `audioTimeRange` por segmento tal como lo entrega la API; no intentar realinear manualmente en el MVP.
- **Videos muy largos consumen tiempo/memoria** → Mitigación: procesar vía streaming de `AVAssetReader` y reportar progreso; sin cargar todo el audio en memoria.
- **Formatos de video no soportados por AVFoundation** → Mitigación: validar el tipo en el drop y mostrar error claro si no es soportado.
