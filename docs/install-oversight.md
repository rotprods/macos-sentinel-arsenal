: # Instalar OverSight

[OverSight](https://objective-see.org/tools.html) de Objective-See te avisa cuando una aplicación accede al micrófono o la cámara de tu Mac. Es gratuito y de código abierto.

## 1. Descargar

1. Abre [https://objective-see.org/tools.html](https://objective-see.org/tools.html).
2. Busca **OverSight**.
3. Descarga el archivo `.zip` o `.dmg` más reciente.

## 2. Instalar

1. Abre el `.dmg` descargado.
2. Arrastra **OverSight.app** a la carpeta **Aplicaciones**.
3. Ejecuta OverSight desde **Aplicaciones**.

## 3. Aprobar permisos

La primera vez que OverSight se ejecuta, macOS pedirá varios permisos:

- **Grabación de pantalla** — necesario para detectar indicadores de micrófono/cámara.
- **Accesibilidad** — para mostrar alertas.
- **Notificaciones** — para avisarte cuando se active el micrófono o cámara.

Acepta todos los que aparezcan.

## 4. Verificar que funciona

1. Abre OverSight.
2. En la barra de menú aparecerá un icono (ojo o similar).
3. Abre **Photo Booth** o **QuickTime Player** y activa la cámara.
4. OverSight debería mostrar una notificación.

## 5. Configuración recomendada

- Deja **OverSight Helper** como elemento de inicio.
- No desactives las notificaciones.
- Mantén la aplicación actualizada.

## Integración con Sentinel Arsenal

OverSight no requiere un LaunchAgent propio en Sentinel Arsenal. Funciona como aplicación residente. Su trabajo es complementar a LuLu, BlockBlock y Malwarebytes con vigilancia de micrófono/cámara.

## Solución de problemas

### No aparecen notificaciones

1. Ve a **Ajustes del Sistema > Notificaciones > OverSight**.
2. Activa **Permitir notificaciones**.
3. Asegúrate de que **Sonidos** también está activo.

### OverSight no detecta la cámara

1. Ve a **Ajustes del Sistema > Privacidad y Seguridad > Grabación de pantalla**.
2. Verifica que OverSight tiene permiso.
3. Reinicia OverSight.

## Más información

- Repositorio oficial: [https://github.com/objective-see/OverSight](https://github.com/objective-see/OverSight)
- Página de Objective-See: [https://objective-see.org/tools.html](https://objective-see.org/tools.html)
