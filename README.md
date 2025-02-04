# Explicación del Script `conv.sh`

Este documento ofrece una explicación detallada del script `conv.sh`, el cual convierte archivos de video MP4 en directorios organizados siguiendo un patrón específico. El script convierte los videos a MP4 utilizando las especificaciones indicadas y ofrece un menú interactivo para cambiar el idioma, alternar la eliminación de audio, iniciar el procesamiento y revisar errores.

## Tabla de Contenidos

- [Visión General](#visión-general)
- [Dependencias y Configuración Inicial](#dependencias-y-configuración-inicial)
- [Variables Globales](#variables-globales)
- [Manejo de Mensajes Multilenguaje](#manejo-de-mensajes-multilenguaje)
- [Cambio de Idioma](#cambio-de-idioma)
- [Alternar Eliminación de Audio](#alternar-eliminación-de-audio)
- [Detección de CUDA](#detección-de-cuda)
- [Procesamiento de Videos](#procesamiento-de-videos)
  - [Búsqueda de Carpetas y Archivos](#búsqueda-de-carpetas-y-archivos)
  - [Conversión de Archivos](#conversión-de-archivos)
  - [Ejecución en Paralelo y Registro de Logs](#ejecución-en-paralelo-y-registro-de-logs)
- [Revisión de Archivos Convertidos](#revisión-de-archivos-convertidos)
- [Menú Interactivo](#menú-interactivo)
- [Resumen y Conclusiones](#resumen-y-conclusiones)

## Visión General

El script `conv.sh` está diseñado para:

- **Buscar carpetas de video:** Detecta carpetas que siguen el patrón `TXXL` o `TXXR` (por ejemplo, `T1L`, `T1R`, `T2L`, etc.) en el directorio base.
- **Convertir videos:** Procesa cada archivo MP4 encontrado y lo convierte a un nuevo archivo MP4 utilizando:
  - **Contenedor:** MP4.
  - **Códec de video:** H.264. Se usa `h264_nvenc` si se dispone de CUDA, o `libx264` en caso contrario.
  - **Bitrate:** 8126532.
  - **Resolución:** 1920x1080.
  - **Frame rate:** 30 FPS.
  - **Audio:** Se puede eliminar o codificar en MP3 (usando `-an` o `-c:a libmp3lame` respectivamente).
- **Paralelismo:** Ejecuta hasta 4 conversiones simultáneas para optimizar el tiempo de procesamiento.
- **Logs:** Guarda el resultado de cada conversión en `conv/conv_log.txt`.
- **Interfaz interactiva:** Permite cambiar el idioma, alternar la eliminación del audio, iniciar el procesamiento o revisar errores a través de un menú.

## Dependencias y Configuración Inicial

El script comienza verificando que `ffmpeg` esté instalado en el sistema. Si no se encuentra, muestra un mensaje de error y finaliza:

```bash
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg no está instalado. Por favor, instálelo."
    exit 1
fi
```

También define la variable `BASE_DIR` para indicar el directorio base donde se buscarán las carpetas. Si se pasa un parámetro al script, se usará ese directorio; de lo contrario, se usa el directorio actual.

Se activa el globbing insensible a mayúsculas/minúsculas con:

```bash
shopt -s nocaseglob
```

Esto permite que el patrón `*.mp4` detecte archivos sin importar si la extensión está en minúsculas o mayúsculas.

## Variables Globales

- **LANGUAGE:** Define el idioma del script (por defecto "es" para español).
- **AUDIO_REMOVAL:** Determina si se eliminará el audio de los videos convertidos (`true` o `false`).
- **BASE_DIR:** Directorio base de búsqueda.

## Manejo de Mensajes Multilenguaje

La función `get_msg` centraliza todos los mensajes que se muestran al usuario, permitiendo cambiar de idioma de forma consistente. Por ejemplo:

```bash
get_msg() {
    local msg_id="$1"
    case "$msg_id" in
        header)
            if [ "$LANGUAGE" == "es" ]; then
                echo "🎥 Script de Procesamiento de Videos - FCD 2025"
            else
                echo "🎥 Video Processing Script - FCD 2025"
            fi
            ;;
        ...
    esac
}
```

## Cambio de Idioma

La función `cambiar_idioma` permite al usuario seleccionar entre español e inglés:

```bash
cambiar_idioma() {
    local choice
    echo "$(get_msg prompt_language)"
    read -p "> " choice
    case "$choice" in
        1) LANGUAGE="es" ;;
        2) LANGUAGE="en" ;;
        *) echo "❌ Opcion invalida, se mantiene Español."; LANGUAGE="es" ;;
    esac
    echo "$(get_msg language_changed)"
}
```

## Resumen y Conclusiones

- **Modularidad y Mantenimiento:**  
  El script se estructura en funciones claramente definidas, lo que facilita la comprensión y futuras modificaciones.

- **Soporte Multilenguaje:**  
  Gracias a la función `get_msg`, todos los mensajes se centralizan, permitiendo cambiar el idioma de manera consistente.

- **Procesamiento Paralelo:**  
  El uso de procesos en segundo plano (limitados a 4 simultáneos) permite procesar grandes volúmenes de archivos de forma eficiente.

- **Aceleración por GPU:**  
  La función `check_cuda` permite utilizar la aceleración de GPU (NVENC) si está disponible, optimizando la conversión de video.

- **Logs y Diagnóstico:**  
  Se generan logs detallados en cada carpeta (`conv/conv_log.txt`), lo que facilita la revisión y solución de problemas en caso de errores.

- **Interfaz Interactiva:**  
  El menú interactivo y los mensajes con iconos (🔎, 🎬, ✅, ❌, etc.) hacen que la experiencia del usuario sea clara y amigable.


