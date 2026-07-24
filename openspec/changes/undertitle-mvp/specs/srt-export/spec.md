## ADDED Requirements

### Requirement: Generación del archivo SRT
La aplicación SHALL convertir los segmentos transcritos (texto + rangos de tiempo) en un archivo `.SRT` válido, con bloques numerados secuencialmente y timestamps en formato `HH:MM:SS,mmm`.

#### Scenario: Segmentos a SRT
- **WHEN** la transcripción produce uno o más segmentos con texto y rangos de tiempo
- **THEN** la aplicación genera contenido SRT donde cada bloque tiene índice incremental, línea de tiempo `inicio --> fin` y el texto del segmento

#### Scenario: Formato de timestamp
- **WHEN** un segmento tiene tiempos de inicio y fin
- **THEN** los timestamps se formatean como `HH:MM:SS,mmm` (milisegundos separados por coma)

### Requirement: Guardado del archivo SRT
La aplicación SHALL permitir al usuario guardar el archivo `.SRT` generado en una ubicación de su elección una vez finalizada la transcripción.

#### Scenario: Guardar el SRT
- **WHEN** la transcripción finaliza correctamente y el usuario elige guardar/descargar
- **THEN** la aplicación escribe el archivo `.SRT` en la ubicación seleccionada por el usuario

#### Scenario: Nombre por defecto basado en el video
- **WHEN** el usuario va a guardar el SRT
- **THEN** la aplicación propone como nombre por defecto el del video original con extensión `.srt`
