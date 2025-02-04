# Explicación del Script `def_conv2.sh`

Este documento ofrece una explicación detallada del script `def_conv2.sh`, el cual convierte archivos de video MP4 en directorios organizados siguiendo un patrón específico. El script convierte los videos a MP4 usando las especificaciones indicadas y ofrece un menú interactivo para cambiar el idioma, alternar la eliminación de audio, iniciar el procesamiento y revisar errores.

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

El script `def_conv2.sh` está diseñado para:

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
También define la variable BASE_DIR para indicar el directorio base donde se buscarán las carpetas. Si se pasa un parámetro, se usará ese directorio; de lo contrario, se usa el directorio actual.

Se activa el globbing insensible a mayúsculas/minúsculas con:

shopt -s nocaseglob

Esto permite que el patrón *.mp4 detecte archivos sin importar si la extensión está en minúsculas o mayúsculas.
Variables Globales

    LANGUAGE: Define el idioma del script (por defecto "es" para español).
    AUDIO_REMOVAL: Determina si se eliminará el audio de los videos convertidos (true o false).
    BASE_DIR: Directorio base de búsqueda.

Manejo de Mensajes Multilenguaje

La función get_msg centraliza todos los mensajes que se muestran al usuario, permitiendo cambiar de idioma de forma consistente. Por ejemplo:

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

Cambio de Idioma

La función cambiar_idioma permite al usuario seleccionar entre español e inglés:

cambiar_idioma() {
    local choice
    echo "$(get_msg prompt_language)"
    read -p "> " choice
    case "$choice" in
        1) LANGUAGE="es" ;;
        2) LANGUAGE="en" ;;
        *) echo "❌ Opción inválida, se mantiene Español."; LANGUAGE="es" ;;
    esac
    echo "$(get_msg language_changed)"
}

Alternar Eliminación de Audio

La función toggle_audio invierte el valor de AUDIO_REMOVAL y muestra el estado actual:

toggle_audio() {
    if $AUDIO_REMOVAL; then
        AUDIO_REMOVAL=false
    else
        AUDIO_REMOVAL=true
    fi
    echo "$(get_msg audio_status)"
}

Detección de CUDA

La función check_cuda verifica si nvidia-smi está disponible para determinar si se puede usar la aceleración por GPU:

check_cuda() {
    if command -v nvidia-smi &> /dev/null; then
        return 0    # CUDA disponible
    else
        return 1    # CUDA no disponible
    fi
}

Procesamiento de Videos

Esta función es el núcleo del script y se divide en varias etapas:
Búsqueda de Carpetas y Archivos

Se buscan carpetas que sigan el patrón T[0-9]+[LR] en el directorio base utilizando:

dirs=$(find "$BASE_DIR" -maxdepth 1 -type d -regextype posix-extended -regex ".*/T[0-9]+[LR]$" | sort -V)

El script lista estas carpetas y cuenta el número total de archivos MP4 que se van a procesar.
Conversión de Archivos

Para cada carpeta:

    Se crea la subcarpeta conv/ si no existe.

    Se recorren los archivos MP4 usando un glob (insensible a mayúsculas, gracias a nocaseglob):

    for file in "$d"/*.mp4; do
        [ -e "$file" ] || continue
        ...
    done

    El archivo de salida se nombra combinando el nombre de la carpeta y el nombre base del archivo original, añadiendo el sufijo _conv.mp4.

Ejecución en Paralelo y Registro de Logs

Cada conversión se lanza en segundo plano (usando { ... } &) y se limita a 4 procesos simultáneos mediante un bucle while:

while [ "$(jobs -r | wc -l)" -ge 4 ]; do
    sleep 1
done

Según la disponibilidad de CUDA y la opción de audio, se utiliza el siguiente bloque para convertir:

{
    if check_cuda; then
        if $AUDIO_REMOVAL; then
            ffmpeg -hwaccel cuda -i "$input_file" -c:v h264_nvenc -b:v 8126532 \
            -s 1920x1080 -r 30 -an -f mp4 "$output_file" > /dev/null 2>&1
        else
            ffmpeg -hwaccel cuda -i "$input_file" -c:v h264_nvenc -b:v 8126532 \
            -s 1920x1080 -r 30 -c:a libmp3lame -f mp4 "$output_file" > /dev/null 2>&1
        fi
    else
        if $AUDIO_REMOVAL; then
            ffmpeg -i "$input_file" -c:v libx264 -b:v 8126532 \
            -s 1920x1080 -r 30 -an -f mp4 "$output_file" > /dev/null 2>&1
        else
            ffmpeg -i "$input_file" -c:v libx264 -b:v 8126532 \
            -s 1920x1080 -r 30 -c:a libmp3lame -f mp4 "$output_file" > /dev/null 2>&1
        fi
    fi
    ...
} &

El resultado de cada conversión se registra en conv/conv_log.txt junto con una marca de tiempo y se muestran mensajes de progreso en pantalla.
Espera y Finalización

El script usa wait para asegurarse de que todos los procesos en segundo plano hayan finalizado antes de indicar que el procesamiento se ha completado.
Revisión de Archivos Convertidos

La función revisar_archivos realiza dos comprobaciones:

    Compara el número de archivos MP4 originales con el número de archivos convertidos (dentro de la carpeta conv/).
    Revisa el archivo de log (conv/conv_log.txt) para detectar errores en las conversiones.

Si hay discrepancias o errores, se muestran mensajes de advertencia para ayudar en la depuración.
Menú Interactivo

El script presenta un menú interactivo en un bucle infinito que permite al usuario realizar las siguientes acciones:

    Cambiar Idioma: Llama a la función cambiar_idioma.
    Eliminar Audio en Archivos MP4: Llama a la función toggle_audio.
    Iniciar Procesamiento de Videos: Llama a la función procesar_videos.
    Revisar Archivos Convertidos y Detectar Errores: Llama a la función revisar_archivos.
    Salir: Termina la ejecución del script.

Cada opción se muestra con iconos y mensajes descriptivos, garantizando que el usuario comprenda el estado actual y el progreso de cada acción.
Resumen y Conclusiones

    Modularidad y Mantenimiento:
    El script se estructura en funciones claramente definidas, lo que facilita la comprensión y futuras modificaciones.

    Soporte Multilenguaje:
    Gracias a la función get_msg, todos los mensajes se centralizan, permitiendo cambiar el idioma de manera consistente.

    Procesamiento Paralelo:
    El uso de procesos en segundo plano (limitados a 4 simultáneos) permite procesar grandes volúmenes de archivos de forma eficiente.

    Aceleración por GPU:
    La función check_cuda permite utilizar la aceleración de GPU (NVENC) si está disponible, optimizando la conversión de video.

    Logs y Diagnóstico:
    Se generan logs detallados en cada carpeta (conv/conv_log.txt), lo que facilita la revisión y solución de problemas en caso de errores.

    Interfaz Interactiva:
    El menú interactivo y los mensajes con iconos (🔎, 🎬, ✅, ❌, etc.) hacen que la experiencia del usuario sea clara y amigable.

Este script es una solución completa y robusta para la conversión automatizada de archivos de video, ideal para entornos con grandes volúmenes de datos y necesidades de procesamiento acelerado.
