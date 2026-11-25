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

echo
echo "Actualizando Ubuntu y los paquetes instalados..."
export DEBIAN_FRONTEND=noninteractive

if ! apt-get update; then
    echo "ERROR: no se pudo actualizar la lista de paquetes."
    exit 1
fi

if ! apt-get upgrade -y; then
    echo "ERROR: no se pudieron actualizar los paquetes."
    exit 1
fi

echo "Actualización del sistema completada."
echo

cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT

if ! command -v curl >/dev/null 2>&1; then
    echo "Instalando curl..."
    apt-get update
    apt-get install -y curl
fi

echo "Descargando CHARLY desde GitHub..."

if ! curl -fL --connect-timeout 15 --max-time 180 \
    "$REPO/charly" -o "$TMP"; then
    echo "ERROR: no se pudo descargar CHARLY."
    exit 1
fi

if ! bash -n "$TMP"; then
    echo "ERROR: el script descargado no es válido."
    exit 1
fi

if ! grep -q '^menu_principal()' "$TMP"; then
    echo "ERROR: no se reconoce el menú CHARLY."
    exit 1
fi

if [[ -e "$DEST" ]]; then
    cp -a "$DEST" "$DEST.backup.$(date +%Y%m%d_%H%M%S)"
fi

install -o root -g root -m 755 "$TMP" "$DEST"
ln -sfn "$DEST" /usr/local/bin/menu

# Inicio automático únicamente para sesiones interactivas de root.
mkdir -p /etc/profile.d
cat > /etc/profile.d/charly-autostart.sh <<'CHARLY_AUTO'
if [ "$(id -u 2>/dev/null)" = "0" ] &&
   [ -n "${PS1:-}" ] &&
   [ -t 0 ] &&
   [ -x /usr/local/bin/charly ] &&
   [ -z "${SSH_ORIGINAL_COMMAND:-}" ] &&
   [ -z "${CHARLY_AUTOSTART_ACTIVE:-}" ]; then
    CHARLY_AUTOSTART_ACTIVE=1
    export CHARLY_AUTOSTART_ACTIVE
    /usr/local/bin/charly
    unset CHARLY_AUTOSTART_ACTIVE
fi
CHARLY_AUTO
chmod 644 /etc/profile.d/charly-autostart.sh

echo
echo "CHARLY instalado correctamente."
echo "El menú aparecerá automáticamente al iniciar sesión SSH como root."
echo "También puedes abrirlo escribiendo: menu"
echo

# Limpiar el temporal antes de entregar la terminal al menú.
rm -f "$TMP"
trap - EXIT
exec "$DEST"
