#!/bin/bash

# =============================
# Script de Respaldo Automático
# =============================

# Carpetas principales
ORIGEN="/home/proyecto"             # Carpeta del proyecto a respaldar
DESTINO="/backups"                  # Carpeta principal de respaldos
FULL="$DESTINO/full"                # Respaldos completos
DIFF="$DESTINO/diferencial"         # Respaldos diferenciales
FECHA=$(date -I)                    # Fecha en formato YYYY-MM-DD

# Crear carpetas si no existen
mkdir -p "$FULL" "$DIFF"

echo "[*] Iniciando proceso de respaldo en $FECHA..."

# ---------------- Respaldo Completo ----------------
# Se hace solo si hoy es múltiplo de 21 días desde inicio del año
if (( $(date +%j) % 21 == 0 )); then
    echo "[*] Creando respaldo COMPLETO..."
    tar -cvzf "$FULL/respaldo_$FECHA.tar.gz" "$ORIGEN"

    echo "[*] Manteniendo solo los 2 respaldos completos más recientes..."
    ls -1t "$FULL"/respaldo_*.tar.gz 2>/dev/null | tail -n +3 | xargs -r rm -f
fi

# ---------------- Respaldo Diferencial ----------------
# Se hace solo si hoy es múltiplo de 7 días desde inicio del año
if (( $(date +%j) % 7 == 0 )); then
    echo "[*] Creando respaldo DIFERENCIAL..."
    ULTIMO_FULL=$(ls -1t "$FULL"/respaldo_*.tar.gz 2>/dev/null | head -1)

    if [ -z "$ULTIMO_FULL" ]; then
        echo "[!] No existe respaldo completo previo. Abortando diferencial."
    else
        rsync -avz --link-dest="$ORIGEN" "$ORIGEN"/ "$DIFF/$FECHA/"
    fi

    echo "[*] Manteniendo solo los 3 respaldos diferenciales más recientes..."
    ls -1dt "$DIFF"/*/ 2>/dev/null | tail -n +4 | xargs -r rm -rf
fi

echo "[*] Proceso de respaldo finalizado."
#date +%j → devuelve el número del día en el año (1–365).
#Así controlamos que el script solo ejecute full cada 21 días y diferenciales cada 7 días.

#Retención automática:

#ls -1t ... | tail -n +N | xargs -r rm -f → conserva los N-1 más recientes y elimina el resto.

#rsync --link-dest=$ORIGEN → usa enlaces duros para ahorrar espacio en diferenciales (compara con el último full).
