## 1. Setup del proyecto

- [x] 1.1 Crear proyecto SwiftUI para macOS con deployment target macOS 26
- [x] 1.2 Configurar entitlements de sandbox: acceso a archivos seleccionados por el usuario
- [x] 1.3 Definir la estructura de carpetas: `Views/`, `ViewModels/`, `Services/`, `Models/`

## 2. Modelos y estado

- [x] 2.1 Definir el modelo `TranscriptSegment` (texto, inicio, fin)
- [x] 2.2 Definir la enum de estado del proceso (`idle`, `extractingAudio`, `preparingModel`, `transcribing(progress)`, `completed(srtURL)`, `failed(error)`)
- [x] 2.3 Definir el modelo de idioma soportado (display name + `Locale`) con inglés y español

## 3. Servicio de extracción de audio

- [x] 3.1 Implementar `AudioExtractor` con AVFoundation que extrae la pista de audio a formato apto para transcripción
- [x] 3.2 Manejar el caso de video sin pista de audio (lanzar error tipado)
- [x] 3.3 Procesar por streaming con `AVAssetReader` para soportar videos largos sin cargar todo en memoria

## 4. Servicio de transcripción

- [x] 4.1 Implementar `SpeechTranscriptionService` con `SpeechAnalyzer` + `SpeechTranscriber`
- [x] 4.2 Verificar `SpeechTranscriber.supportedLocales` antes de transcribir; error claro si no soportado
- [x] 4.3 Detectar asset de idioma ausente y solicitar descarga vía `AssetInventory`, exponiendo estado de descarga
- [x] 4.4 Emitir segmentos con texto + `audioTimeRange` (inicio/fin) y reportar progreso
- [x] 4.5 Garantizar funcionamiento offline cuando el modelo ya está instalado

## 5. Exportación SRT

- [x] 5.1 Implementar `SRTExporter` que mapea `TranscriptSegment[]` a contenido SRT (índice, `HH:MM:SS,mmm --> HH:MM:SS,mmm`, texto)
- [x] 5.2 Implementar el formateo de timestamps `HH:MM:SS,mmm`
- [x] 5.3 Implementar el guardado con `NSSavePanel`, proponiendo el nombre del video con extensión `.srt`

## 6. ViewModel / orquestación

- [x] 6.1 Implementar `TranscriptionViewModel` (`@Observable`) que orquesta extracción → transcripción → exportación
- [x] 6.2 Publicar el estado del proceso y el progreso hacia la UI
- [x] 6.3 Mapear errores de cada etapa a mensajes claros para el usuario

## 7. UI (SwiftUI)

- [x] 7.1 Implementar `DropView` con `.onDrop`, validación de tipo de video y feedback visual durante el arrastre
- [x] 7.2 Implementar el dropdown de idioma debajo del drop area, default inglés
- [x] 7.3 Implementar la barra de progreso y la indicación del estado actual del pipeline
- [x] 7.4 Implementar el botón/acción de descargar/guardar el `.SRT` al finalizar
- [x] 7.5 Mostrar estados de error y de "descargando modelo de idioma"

## 8. Tests

- [x] 8.1 Test unitario de `SRTExporter`: segmentos → SRT y formato de timestamp
- [x] 8.2 Test unitario de `AudioExtractor`: video con/sin audio
- [x] 8.3 Test de `TranscriptionViewModel`: transiciones de estado del pipeline (con servicios mockeados)

## 9. Verificación final

- [ ] 9.1 Probar end-to-end con un video real en inglés → SRT válido
- [ ] 9.2 Probar end-to-end con un video real en español → SRT válido
- [ ] 9.3 Verificar el flujo de descarga de modelo en un idioma no instalado
- [x] 9.4 Build final: linter, imports, type errors y dependencias
