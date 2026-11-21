
#!/bin/bash
set -Eeuo pipefail

REPO="https://raw.githubusercontent.com/tvmagi009-web/CHARLY-VPS-/main"
DEST="/usr/local/bin/charly"
TMP="$(mktemp)"

clear
echo "======================================"
echo "          CHARLY VPS"
echo "       INSTALADOR OFICIAL"
echo "======================================"
echo

if [[ "$EUID" -ne 0 ]]; then
    echo "Ejecuta este instalador como root."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Instalando curl..."
    apt-get update
    apt-get install -y curl
fi

echo "Descargando CHARLY desde GitHub..."

if ! curl -fL --connect-timeout 15 --max-time 180 \
    "$REPO/charly" -o "$TMP"; then
    echo "ERROR: no se pudo descargar CHARLY."
    rm -f "$TMP"
    exit 1
fi

if ! bash -n "$TMP"; then
    echo "ERROR: el script descargado no es válido."
    rm -f "$TMP"
    exit 1
fi

if ! grep -q '^menu_principal()' "$TMP"; then
    echo "ERROR: no se reconoce el menú CHARLY."
    rm -f "$TMP"
    exit 1
fi

if [[ -e "$DEST" ]]; then
    cp -a "$DEST" "$DEST.backup.$(date +%Y%m%d_%H%M%S)"
fi

install -o root -g root -m 755 "$TMP" "$DEST"
rm -f "$TMP"

ln -sfn "$DEST" /usr/local/bin/menu

echo
echo "CHARLY instalado correctamente."
echo "Para abrirlo, escribe: menu"
echo
