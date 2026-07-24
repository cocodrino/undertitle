## ADDED Requirements

### Requirement: Transcripción on-device del audio
La aplicación SHALL transcribir el audio extraído usando Apple `SpeechAnalyzer` + `SpeechTranscriber` en el dispositivo, sin enviar audio a servicios externos, produciendo segmentos de texto con sus rangos de tiempo (`audioTimeRange`).

#### Scenario: Transcripción exitosa
- **WHEN** se transcribe un audio en un idioma soportado con su modelo disponible
- **THEN** la aplicación produce una secuencia de segmentos, cada uno con texto, tiempo de inicio y tiempo de fin

#### Scenario: Transcripción offline
- **WHEN** el modelo de idioma ya está instalado en el dispositivo y no hay conexión a internet
- **THEN** la transcripción se completa igualmente sin requerir red

### Requirement: Gestión de locales soportados
La aplicación SHALL verificar que el locale seleccionado esté incluido en `SpeechTranscriber.supportedLocales` antes de transcribir.

#### Scenario: Locale soportado
- **WHEN** el usuario selecciona un idioma cuyo locale está en la lista de soportados
- **THEN** la aplicación procede con la transcripción

#### Scenario: Locale no soportado
- **WHEN** el locale seleccionado no está disponible en el dispositivo
- **THEN** la aplicación muestra un error claro y no inicia la transcripción

### Requirement: Descarga del modelo de idioma
La aplicación SHALL solicitar la descarga del modelo de idioma vía `AssetInventory` cuando el asset del locale seleccionado no esté presente, informando el estado al usuario.

#### Scenario: Modelo ausente en la primera ejecución
- **WHEN** el usuario inicia una transcripción con un idioma cuyo modelo no está instalado
- **THEN** la aplicación inicia la descarga del modelo y muestra un estado "descargando modelo de idioma" antes de transcribir

#### Scenario: Modelo ya disponible
- **WHEN** el modelo del idioma seleccionado ya está instalado
- **THEN** la aplicación transcribe directamente sin paso de descarga
