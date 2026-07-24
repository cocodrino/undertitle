## ADDED Requirements

### Requirement: Extracción de audio del video
La aplicación SHALL extraer la pista de audio del video soltado y convertirla a un formato apto para la transcripción on-device, usando frameworks nativos de Apple sin dependencias externas.

#### Scenario: Video con pista de audio
- **WHEN** se procesa un video que contiene una pista de audio
- **THEN** la aplicación extrae el audio en un formato consumible por el motor de transcripción

#### Scenario: Video sin pista de audio
- **WHEN** se procesa un video que no contiene ninguna pista de audio
- **THEN** la aplicación aborta el proceso y muestra un error indicando que el video no tiene audio

#### Scenario: Procesamiento de videos largos
- **WHEN** se procesa un video de larga duración
- **THEN** la extracción de audio se realiza por streaming sin cargar el archivo completo en memoria
