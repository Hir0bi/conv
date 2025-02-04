# Explicación del Script `def_conv2.sh`

Este documento ofrece una explicación detallada del script `def_conv2.sh`, el cual convierte archivos de video MP4 en directorios organizados siguiendo un patrón específico. El script convierte los videos a MP4 utilizando las especificaciones indicadas y ofrece un menú interactivo para cambiar el idioma, alternar la eliminación de audio, iniciar el procesamiento y revisar errores.

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

