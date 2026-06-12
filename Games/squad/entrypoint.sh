#!/bin/bash

# -------------------------------------------------------
# Squad Dedicated Server - Entrypoint
# Image: registry.molret.dev/cybrancee/squad:latest
#
# Port derivation (multi-tenant, from primary allocation):
#   SERVER_PORT      = X    → game port principal
#   SERVER_PORT + 1  = X+1  → game port secundario (manejado internamente por el binario)
#   SERVER_PORT + 2  = X+2  → query port (Steam browser)
#   SERVER_PORT + 3  = X+3  → beacon port
#
# Server.cfg es gestionado por el parser de Pterodactyl.
# NO se parchea aquí.
# -------------------------------------------------------

export QUERY_PORT=$((SERVER_PORT + 2))
export BEACON_PORT=$((SERVER_PORT + 3))

echo "--------------------------------------------"
echo " Squad Dedicated Server"
echo "--------------------------------------------"
echo " Game Port   : ${SERVER_PORT} (+ $((SERVER_PORT + 1)) internal)"
echo " Query Port  : ${QUERY_PORT}"
echo " Beacon Port : ${BEACON_PORT}"
echo "--------------------------------------------"

# ---- Auto-update (controlled by AUTO_UPDATE variable) ----
if [[ "${AUTO_UPDATE}" == "1" ]]; then
    echo "[Squad] Checking for updates (AppID: ${SRCDS_APPID})..."
    /home/container/steamcmd/steamcmd.sh \
        +force_install_dir /home/container \
        +login anonymous \
        +app_update ${SRCDS_APPID} validate \
        +quit
    echo "[Squad] Update check done."
fi

# ---- Workshop mods ----
if [[ -n "${WORKSHOP_ITEMS}" ]]; then
    echo "[Squad] Downloading Workshop mods: ${WORKSHOP_ITEMS}"

    WORKSHOP_CMD=""
    IFS=',' read -ra MODS <<< "${WORKSHOP_ITEMS}"
    for MOD in "${MODS[@]}"; do
        MOD="$(echo "${MOD}" | tr -d '[:space:]')"
        [[ -z "${MOD}" ]] && continue
        WORKSHOP_CMD="${WORKSHOP_CMD} +workshop_download_item 393380 ${MOD}"
    done

    if [[ -n "${WORKSHOP_CMD}" ]]; then
        /home/container/steamcmd/steamcmd.sh \
            +force_install_dir /home/container \
            +login anonymous \
            ${WORKSHOP_CMD} \
            +quit

        MOD_SRC="/home/container/steamapps/workshop/content/393380"
        MOD_DST="/home/container/SquadGame/Plugins/Mods"
        if [[ -d "${MOD_SRC}" ]]; then
            mkdir -p "${MOD_DST}"
            mv -f "${MOD_SRC}/"* "${MOD_DST}/" 2>/dev/null || true
            echo "[Squad] Mods moved to ${MOD_DST}"
        fi
        rm -f /home/container/steamapps/workshop/appworkshop_393380.acf
    fi
fi

# ---- Sanity check ----
BINARY="/home/container/SquadGame/Binaries/Linux/SquadGameServer"
if [[ ! -f "${BINARY}" ]]; then
    echo "[Squad] ERROR: Binary not found at ${BINARY}"
    echo "[Squad] Run a reinstall from the panel."
    exit 1
fi

# ---- Launch ----
echo "[Squad] Starting server..."
exec "${BINARY}" SquadGame \
    Port=${SERVER_PORT} \
    QueryPort=${QUERY_PORT} \
    -beaconport=${BEACON_PORT} \
    -log
