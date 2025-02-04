#!/bin/bash
###############################################################################
# def_conv2.sh
#
# Script para la conversión de archivos de video MP4 en directorios organizados
# bajo la estructura TXXL o TXXR. Realiza la conversión usando ffmpeg con las
# siguientes opciones:
#
#   - Contenedor: MP4
#   - Códec de video: H.264 (usando NVENC si CUDA está disponible, o libx264)
#   - Bitrate: 8126532
#   - Resolución: 1920x1080
#   - Frame rate: 30 FPS
#   - Códec de audio: MP3 (o eliminar audio si se activa la opción)
#
# Además, el script:
#   • Permite ejecutar desde una ruta especificada (o usa la carpeta actual)
#   • Busca carpetas en orden ascendente (T1L, T1R, T2L, T2R, …)
#   • Crea automáticamente la subcarpeta "conv/" (si no existe) en cada carpeta
#   • Añade al nombre de salida el nombre de la carpeta padre y el sufijo "_conv"
#   • Guarda un log de conversiones en conv/conv_log.txt
#   • Procesa los archivos en paralelo (máximo 4 a la vez)
#   • Tiene menú interactivo con opciones para cambiar idioma, alternar audio,
#     iniciar procesamiento, revisar errores y salir.
#
# Autor: MGM 2025 – Fundación Charles Darwin en Galápagos (Departamento de Tiburones)
###############################################################################

# Verificar que ffmpeg esté instalado
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg no está instalado. Por favor, instálelo."
    exit 1
fi

# --- Variables Globales ---
LANGUAGE="es"         # Idioma por defecto: español (puede cambiarse a "en")
AUDIO_REMOVAL=true    # Por defecto se elimina el audio
BASE_DIR="."          # Directorio base de búsqueda (se puede pasar como parámetro)

# Si se especifica una ruta como parámetro, se usa esa ruta
if [ -n "$1" ]; then
    BASE_DIR="$1"
fi

if [ ! -d "$BASE_DIR" ]; then
    echo "Directorio \"$BASE_DIR\" no encontrado."
    exit 1
fi

# Activar globbing insensible a mayúsculas/minúsculas para detectar *.mp4 o *.MP4
shopt -s nocaseglob

# --- Función para obtener mensajes según el idioma seleccionado ---
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
        intro)
            if [ "$LANGUAGE" == "es" ]; then
                echo "📢 Este script ha sido desarrollado para el departamento de Tiburones
de la Fundación Charles Darwin en Galápagos por MGM 2025."
            else
                echo "📢 This script has been developed for the Sharks department
of the Charles Darwin Foundation in Galápagos by MGM 2025."
            fi
            ;;
        what_does)
            if [ "$LANGUAGE" == "es" ]; then
                echo "🔍 ¿Qué hace este script?"
            else
                echo "🔍 What does this script do?"
            fi
            ;;
        features)
            if [ "$LANGUAGE" == "es" ]; then
                echo "   ✅ Busca carpetas de videos (TXXL o TXXR) y procesa archivos MP4 en orden correcto."
                echo "   ✅ Crea una carpeta 'conv/' para los videos convertidos."
                echo "   ✅ Añade el nombre de la carpeta padre a los archivos convertidos."
                echo "   ✅ Procesa videos en paralelo (máximo 4 procesos a la vez)."
                echo "   ✅ Guarda registros de conversión en 'conv/conv_log.txt'."
                echo "   ✅ Opción para eliminar audio de los videos convertidos."
            else
                echo "   ✅ Searches for video folders (TXXL or TXXR) and processes MP4 files in correct order."
                echo "   ✅ Creates a 'conv/' folder for the converted videos."
                echo "   ✅ Prepends the parent folder name to the converted files."
                echo "   ✅ Processes videos in parallel (max 4 processes at once)."
                echo "   ✅ Saves conversion logs in 'conv/conv_log.txt'."
                echo "   ✅ Option to remove audio from the converted videos."
            fi
            ;;
        audio_status)
            if [ "$LANGUAGE" == "es" ]; then
                if $AUDIO_REMOVAL; then
                    echo "🔊 Se quitará el sonido en los archivos convertidos."
                else
                    echo "🔊 Los archivos de salida tendrán audio."
                fi
            else
                if $AUDIO_REMOVAL; then
                    echo "🔊 Audio will be removed from the converted files."
                else
                    echo "🔊 Output files will have audio."
                fi
            fi
            ;;
        separator)
            echo "=================================================="
            ;;
        menu_options)
            if [ "$LANGUAGE" == "es" ]; then
                echo "1️⃣ Cambiar Idioma"
                echo "2️⃣ Eliminar Audio en Archivos MP4"
                echo "3️⃣ Iniciar Procesamiento de Videos"
                echo "4️⃣ Revisar archivos convertidos y detectar errores"
                echo "5️⃣ Salir"
                echo ""
                echo "👉 Seleccione una opción:"
            else
                echo "1️⃣ Change Language"
                echo "2️⃣ Toggle Audio Removal in MP4 Files"
                echo "3️⃣ Start Video Processing"
                echo "4️⃣ Check Converted Files and Detect Errors"
                echo "5️⃣ Exit"
                echo ""
                echo "👉 Select an option:"
            fi
            ;;
        invalid_option)
            if [ "$LANGUAGE" == "es" ]; then
                echo "❌ Opción inválida. Inténtelo de nuevo."
            else
                echo "❌ Invalid option. Please try again."
            fi
            ;;
        processing_start)
            if [ "$LANGUAGE" == "es" ]; then
                echo "⏳ Iniciando procesamiento de videos..."
            else
                echo "⏳ Starting video processing..."
            fi
            ;;
        processing_complete)
            if [ "$LANGUAGE" == "es" ]; then
                echo "✅ Procesamiento completado."
            else
                echo "✅ Processing complete."
            fi
            ;;
        exit_message)
            if [ "$LANGUAGE" == "es" ]; then
                echo "👋 Saliendo del script. ¡Hasta luego!"
            else
                echo "👋 Exiting script. Goodbye!"
            fi
            ;;
        language_changed)
            if [ "$LANGUAGE" == "es" ]; then
                echo "🌍 Idioma cambiado a Español."
            else
                echo "🌍 Language changed to English."
            fi
            ;;
        prompt_language)
            if [ "$LANGUAGE" == "es" ]; then
                echo "Seleccione el idioma: 1. Español 2. Inglés"
            else
                echo "Select language: 1. Spanish 2. English"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# --- Función para cambiar el idioma ---
cambiar_idioma() {
    local choice
    echo "$(get_msg prompt_language)"
    read -p "> " choice
    case "$choice" in
        1)
            LANGUAGE="es"
            ;;
        2)
            LANGUAGE="en"
            ;;
        *)
            if [ "$LANGUAGE" == "es" ]; then
                echo "❌ Opción inválida, se mantiene Español."
            else
                echo "❌ Invalid option, keeping Spanish."
            fi
            LANGUAGE="es"
            ;;
    esac
    echo "$(get_msg language_changed)"
}

# --- Función para activar/desactivar la eliminación de audio ---
toggle_audio() {
    if $AUDIO_REMOVAL; then
        AUDIO_REMOVAL=false
    else
        AUDIO_REMOVAL=true
    fi
    echo "$(get_msg audio_status)"
}

# --- Función para detectar si CUDA está disponible ---
check_cuda() {
    if command -v nvidia-smi &> /dev/null; then
        return 0    # CUDA disponible
    else
        return 1    # CUDA no disponible
    fi
}

# --- Función para procesar los videos ---
procesar_videos() {
    echo ""
    echo "$(get_msg processing_start)"
    echo ""

    # Mostrar la ruta base y las carpetas encontradas
    echo "🔎 Buscando carpetas de video en: $BASE_DIR"
    dirs=$(find "$BASE_DIR" -maxdepth 1 -type d -regextype posix-extended -regex ".*/T[0-9]+[LR]$" | sort -V)
    if [ -z "$dirs" ]; then
        echo "⚠️ No se encontraron carpetas con el formato TXXL o TXXR en $BASE_DIR."
        return
    fi

    echo "📁 Carpetas encontradas:"
    for d in $dirs; do
        echo "   • $(basename "$d")"
    done

    # Contar el total de archivos MP4 en todas las carpetas válidas
    total_files=0
    for d in $dirs; do
        count=$(find "$d" -maxdepth 1 -type f -iname "*.mp4" | wc -l)
        total_files=$(( total_files + count ))
    done

    if [ $total_files -eq 0 ]; then
        echo "⚠️ No se encontraron archivos MP4 para procesar en \"$BASE_DIR\"."
        return
    else
        echo "📂 Se encontraron $total_files archivo(s) MP4 para procesar."
    fi

    processed_files=0
    # Procesar cada carpeta en orden
    for d in $dirs; do
        folder_name=$(basename "$d")
        conv_dir="$d/conv"
        # Crear la carpeta conv/ si no existe
        if [ ! -d "$conv_dir" ]; then
            mkdir "$conv_dir"
            echo "🗂️  Se creó la carpeta: $conv_dir"
        fi
        log_file="$conv_dir/conv_log.txt"

        # Procesar cada archivo MP4 en la carpeta (usando glob insensible a mayúsculas/minúsculas)
        for file in "$d"/*.mp4; do
            [ -e "$file" ] || continue  # Salta si no existen archivos .mp4
            input_file="$file"
            base_file=$(basename "$file")
            file_name="${base_file%.*}"
            # Construir el nombre de salida (extensión .mp4)
            output_file="$conv_dir/${folder_name}_${file_name}_conv.mp4"

            # Si el archivo ya existe, se salta
            if [ -f "$output_file" ]; then
                echo "ℹ️  [${folder_name}] $base_file ya fue convertido, se omite."
                continue
            fi

            # Mostrar mensaje de inicio de conversión para el archivo
            echo "🎬 [${folder_name}] Iniciando conversión de: $base_file"

            {
                # Seleccionar parámetros según disponibilidad de CUDA y eliminación de audio
                if check_cuda; then
                    # Si CUDA está disponible, usamos NVENC para H.264
                    if $AUDIO_REMOVAL; then
                        ffmpeg -hwaccel cuda -i "$input_file" -c:v h264_nvenc -b:v 8126532 \
                        -s 1920x1080 -r 30 -an -f mp4 "$output_file" > /dev/null 2>&1
                    else
                        ffmpeg -hwaccel cuda -i "$input_file" -c:v h264_nvenc -b:v 8126532 \
                        -s 1920x1080 -r 30 -c:a libmp3lame -f mp4 "$output_file" > /dev/null 2>&1
                    fi
                else
                    # Si no hay CUDA, usamos libx264
                    if $AUDIO_REMOVAL; then
                        ffmpeg -i "$input_file" -c:v libx264 -b:v 8126532 \
                        -s 1920x1080 -r 30 -an -f mp4 "$output_file" > /dev/null 2>&1
                    else
                        ffmpeg -i "$input_file" -c:v libx264 -b:v 8126532 \
                        -s 1920x1080 -r 30 -c:a libmp3lame -f mp4 "$output_file" > /dev/null 2>&1
                    fi
                fi

                exit_status=$?
                if [ $exit_status -eq 0 ]; then
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Conversion OK: $input_file -> $output_file" >> "$log_file"
                    echo "✅ [${folder_name}] Finalizada conversión de: $base_file"
                else
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ ERROR converting: $input_file" >> "$log_file"
                    echo "❌ [${folder_name}] Error en conversión de: $base_file"
                fi
            } &

            # Limitar a 4 procesos en paralelo
            while [ "$(jobs -r | wc -l)" -ge 4 ]; do
                sleep 1
            done

            processed_files=$(( processed_files + 1 ))
            echo "🔢 Progreso: [$processed_files/$total_files] archivos procesados."
        done
    done

    # Esperar a que terminen todos los procesos en segundo plano
    wait
    echo ""
    echo "$(get_msg processing_complete)"
    echo ""
}

# --- Función para revisar los archivos convertidos y detectar errores ---
revisar_archivos() {
    echo ""
    if [ "$LANGUAGE" == "es" ]; then
        echo "🔎 Revisando conversiones y detectando errores..."
    else
        echo "🔎 Reviewing conversions and detecting errors..."
    fi
    echo ""

    error_found=false
    for d in $(find "$BASE_DIR" -maxdepth 1 -type d -regextype posix-extended -regex ".*/T[0-9]+[LR]$" | sort -V); do
        folder_name=$(basename "$d")
        conv_dir="$d/conv"

        if [ ! -d "$conv_dir" ]; then
            echo "⚠️ No se encontró la carpeta 'conv/' en $d"
            error_found=true
            continue
        fi

        log_file="$conv_dir/conv_log.txt"
        orig_count=$(find "$d" -maxdepth 1 -type f -iname "*.mp4" | wc -l)
        conv_count=$(find "$conv_dir" -maxdepth 1 -type f -iname "*.mp4" | wc -l)

        if [ "$orig_count" -ne "$conv_count" ]; then
            echo "⚠️ [${folder_name}] Discrepancia: Originales: $orig_count, Convertidos: $conv_count"
            error_found=true
        fi

        if [ -f "$log_file" ]; then
            errors=$(grep -i "ERROR" "$log_file")
            if [ ! -z "$errors" ]; then
                echo "❌ Errores en $folder_name:"
                echo "$errors"
                error_found=true
            fi
        fi
    done

    if ! $error_found; then
        echo "✅ No se detectaron errores en los archivos convertidos."
    fi
    echo ""
}

# --- Menú interactivo ---
while true; do
    clear
    echo "$(get_msg separator)"
    echo "  $(get_msg header)"
    echo "$(get_msg separator)"
    echo "$(get_msg intro)"
    echo ""
    echo "$(get_msg what_does)"
    get_msg features
    echo "$(get_msg separator)"
    get_msg audio_status
    echo "$(get_msg separator)"
    echo ""
    get_msg menu_options

    read -p "> " option
    case $option in
        1)
            cambiar_idioma
            read -p "Presione Enter para continuar..." dummy
            ;;
        2)
            toggle_audio
            read -p "Presione Enter para continuar..." dummy
            ;;
        3)
            procesar_videos
            read -p "Presione Enter para continuar..." dummy
            ;;
        4)
            revisar_archivos
            read -p "Presione Enter para continuar..." dummy
            ;;
        5)
            echo ""
            echo "$(get_msg exit_message)"
            exit 0
            ;;
        *)
            echo "$(get_msg invalid_option)"
            sleep 2
            ;;
    esac
done