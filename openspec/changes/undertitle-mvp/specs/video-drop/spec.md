## ADDED Requirements

### Requirement: Recepción de video por drag & drop
La aplicación SHALL presentar un área de drag & drop donde el usuario pueda soltar un único archivo de video local para iniciar el proceso de subtitulado.

#### Scenario: Soltar un archivo de video válido
- **WHEN** el usuario arrastra y suelta un archivo de video con formato soportado sobre el área de drop
- **THEN** la aplicación acepta el archivo y queda listo para iniciar la transcripción con el idioma seleccionado

#### Scenario: Soltar un archivo no soportado
- **WHEN** el usuario suelta un archivo cuyo tipo no es un video soportado
- **THEN** la aplicación rechaza el archivo y muestra un mensaje de error claro indicando que el formato no es válido

#### Scenario: Indicación visual durante el arrastre
- **WHEN** el usuario arrastra un archivo sobre el área de drop sin soltarlo
- **THEN** el área cambia su apariencia para indicar que aceptará el archivo

### Requirement: Selección de idioma de transcripción
La aplicación SHALL ofrecer un selector (dropdown) ubicado debajo del área de drop que permita elegir el idioma de transcripción, con inglés como valor por defecto.

#### Scenario: Idioma por defecto
- **WHEN** la aplicación se abre por primera vez
- **THEN** el selector de idioma muestra inglés (`en-US`) como opción seleccionada por defecto

#### Scenario: Cambiar a español
- **WHEN** el usuario abre el selector y elige español
- **THEN** la aplicación usará el locale `es-ES` para la siguiente transcripción
