## ADDED Requirements

### Requirement: Reporte de progreso del proceso
La aplicación SHALL mostrar el progreso del proceso de transcripción mediante una barra de progreso y reflejar el estado actual del pipeline.

#### Scenario: Progreso durante la transcripción
- **WHEN** la transcripción está en curso
- **THEN** la barra de progreso se actualiza reflejando el avance hasta completarse

#### Scenario: Estados del proceso visibles
- **WHEN** el proceso transita entre etapas (extrayendo audio, preparando/descargando modelo, transcribiendo, completado, error)
- **THEN** la aplicación comunica claramente al usuario en qué etapa se encuentra

#### Scenario: Error durante el proceso
- **WHEN** ocurre un error en cualquier etapa del pipeline
- **THEN** la aplicación detiene el progreso y muestra un mensaje de error describiendo la falla
