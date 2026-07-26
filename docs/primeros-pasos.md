: # Primeros pasos: nunca has usado Terminal

> Esta guía es para quien nunca ha abierto Terminal. Si ya sabes usar `bash`/`zsh`, ve directamente a [`00-quickstart.md`](./00-quickstart.md).

## Qué es Terminal

Terminal es la aplicación de macOS que te permite escribir comandos de texto para controlar el ordenador. Es como una conversación directa con macOS.

## 1. Abrir Terminal

1. Pulsa `Cmd + Espacio`.
2. Escribe `Terminal`.
3. Pulsa `Enter`.

Aparecerá una ventana negra con texto. Eso es Terminal.

## 2. Dar permisos a Terminal

Muchos de estos comandos necesitan acceder a archivos del sistema. macOS pedirá permisos la primera vez.

Si ves un mensaje como *"Terminal quiere acceder a archivos de Documentos"* o *"Acceso al disco"*:

1. Ve a **Ajustes del Sistema > Privacidad y Seguridad > Acceso completo al disco**.
2. Activa el interruptor de **Terminal**.
3. Reinicia Terminal.

## 3. Copiar y pegar comandos

En Terminal no uses `Ctrl+C`/`Ctrl+V` (eso interrumpe o no funciona). Usa:

- **Copiar:** selecciona texto → `Cmd+C`
- **Pegar:** `Cmd+V`

## 4. Instalar todo paso a paso

Paso 1: copia este comando y pégalo en Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/rotprods/macos-sentinel-arsenal/main/install.sh -o /tmp/install-sentinel.sh
```

Paso 2: revisa el archivo (esto abre el contenido para que lo veas):

```bash
cat /tmp/install-sentinel.sh | head -40
```

Paso 3: si estás de acuerdo, ejecútalo:

```bash
bash /tmp/install-sentinel.sh --all --non-interactive
```

> ⚠️ **Importante:** nunca ejecutes un script de internet sin revisarlo primero. El paso 2 te muestra las primeras 40 líneas para que veas qué hace.

## 5. Verificar que todo funciona

Copia y pega:

```bash
launchctl list | grep com.sentinel
```

Deberías ver una lista como esta:

```
com.sentinel.tripwire
com.sentinel.mcp-zombie-killer
com.sentinel.lulu-posture
...
```

## 6. Ver los logs

Los logs son los "diarios" de cada agente. Si algo falla, ahí está la explicación.

```bash
ls ~/.local/share/sentinel-arsenal/logs/
```

Para ver el log del tripwire en tiempo real:

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/tripwire.log
```

Para salir de `tail -f`, pulsa `Ctrl+C`.

## 7. Si algo no funciona

1. No te asustes: los agentes no borran archivos personales.
2. Revisa el log del agente.
3. Mira [`99-troubleshooting.md`](./99-troubleshooting.md).
4. Si usas un asistente de IA, dale [`AGENTS.md`](../AGENTS.md).

## Siguiente paso

Cuando termines aquí, instala las herramientas externas recomendadas:

- [`install-lulu.md`](./install-lulu.md)
- [`install-blockblock.md`](./install-blockblock.md)
- [`install-malwarebytes.md`](./install-malwarebytes.md)
- [`install-oversight.md`](./install-oversight.md)
