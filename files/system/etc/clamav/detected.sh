#!/bin/bash

LOG_DIR="$HOME/log"
LOG="$LOG_DIR/scan.log"
TARGET="$HOME"
ARCHIVO_RESUMEN=$(mktemp)

if [[ ! -d "$LOG_DIR" ]]; then
  mkdir -p "$LOG_DIR"
fi

# Inicio del escaneo
echo "------------ INICIO DEL ESCANEO ------------" >> "$LOG"
echo "Ejecutando escaneo en $(date)" >> "$LOG"

# Notificación de inicio
notify-send -i system-run "Escaneo de virus iniciado" "Iniciando escaneo en $TARGET..."

# Escanear con ClamAV
clamscan --bell -i -r "$TARGET" -l "$LOG" > "$ARCHIVO_RESUMEN" 2>&1

ESTADO_ESCANEO="$?"
RESUMEN_INFECCIONES=$(grep "Infected" "$ARCHIVO_RESUMEN")
ERROR_BASE_DATOS=$(grep -E "LibClamAV Error: cl_load\(\): No such file|Can't get file status" "$ARCHIVO_RESUMEN")

# Eliminar archivo temporal
rm "$ARCHIVO_RESUMEN"

if [[ -n "$ERROR_BASE_DATOS" ]]; then
  # Error crítico: base de datos no encontrada
  notify-send -i dialog-warning "Error de ClamAV" "No se pudo cargar la base de datos de virus. ¿Está actualizado ClamAV?"
  echo "ERROR: No se pudo cargar la base de datos de ClamAV" >> "$LOG"
  echo "$ERROR_BASE_DATOS" >> "$LOG"
elif [[ "$ESTADO_ESCANEO" -ne "0" ]]; then
  # Si se encontraron virus
  if command -v systemd-cat &>/dev/null ; then
    echo "Firma(s) de virus encontrada(s) - $RESUMEN_INFECCIONES" | systemd-cat -t clamav -p emerg
  fi
  notify-send -i dialog-error "¡Virus encontrado!" "$RESUMEN_INFECCIONES"
else
  notify-send -i dialog-information "Escaneo completado" "No se encontraron virus en $TARGET"
fi
