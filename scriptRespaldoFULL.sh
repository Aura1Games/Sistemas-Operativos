# =============================
# Script de Respaldo Automático
# =============================

# Carpetas principales
ORIGEN="/home/proyecto"             # Carpeta del proyecto a respaldar
DESTINO="/opt/respaldos"                  # Carpeta principal de respaldos
FULL="$DESTINO/full"                # Respaldos completos
DIFF="$DESTINO/diferencial"         # Respaldos diferenciales
FECHA=$(date -I)                    # Fecha en formato YYYY-MM-DD

# Crear carpetas si no existen
mkdir -p "$FULL" "$DIFF"

echo "[*] Iniciando proceso de respaldo en $FECHA..."

# ---------------- Respaldo Completo ----------------
echo "-respaldo-carpetaPersonal-full-$FECHA" >> /var/log/proyectoAura.log
echo "[*] Creando respaldo COMPLETO..."
tar -cvzf "$FULL/respaldo_$FECHA.tar.gz" "$ORIGEN"
echo "[*] Manteniendo solo los 2 respaldos completos más recientes..."
ls -1t "$FULL"/respaldo_*.tar.gz 2>/dev/null | tail -n +3 | xargs -r rm -f
