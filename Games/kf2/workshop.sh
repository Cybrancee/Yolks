#!/bin/bash
set -euo pipefail

ROOT="${KF2_ROOT:-/home/container}"
STEAMCMD="${STEAMCMD_BIN:-$ROOT/steamcmd/steamcmd.sh}"
WS_BASE="$ROOT/Binaries/Win64"
WS_CONTENT="$WS_BASE/steamapps/workshop/content/232090"
GAME_APPID=232090

ids=$(printf '%s' "${WORKSHOP_IDS:-}" | tr -d '[:space:]')
[ -n "$ids" ] || exit 0
if [[ ! "$ids" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    echo '[Cybrancee] Workshop IDs must be numbers separated by commas.' >&2
    exit 1
fi

cfg="$ROOT/KFGame/Config/LinuxServer-KFEngine.ini"
have_cfg=1
if [ ! -f "$cfg" ]; then
    have_cfg=0
    echo '[Cybrancee] LinuxServer-KFEngine.ini does not exist yet (first start). Workshop items will be downloaded now; restart the server once to apply the Workshop configuration.' >&2
elif [ ! -r "$cfg" ] || [ ! -w "$cfg" ]; then
    echo '[Cybrancee] The Workshop configuration cannot be read or updated.' >&2
    exit 1
fi

IFS=',' read -r -a id_list <<< "$ids"

missing_ids() {
    local id
    for id in "${id_list[@]}"; do
        [ -n "$(ls -A "$WS_CONTENT/$id" 2>/dev/null)" ] || printf '%s\n' "$id"
    done
}

run_steamcmd() {
    local args=() id
    for id in "$@"; do
        args+=(+workshop_download_item "$GAME_APPID" "$id" validate)
    done
    mkdir -p "$WS_BASE"
    export HOME="$ROOT"
    timeout 1800 "$STEAMCMD" +force_install_dir "$WS_BASE" +login anonymous "${args[@]}" +quit || \
        echo "[Cybrancee] SteamCMD exited with an error (see output above)." >&2
}

if [ ! -x "$STEAMCMD" ]; then
    echo "[Cybrancee] SteamCMD not found at $STEAMCMD; skipping Workshop download." >&2
else
    echo "[Cybrancee] Downloading/updating Workshop items: $ids"
    run_steamcmd "${id_list[@]}"

    mapfile -t retry < <(missing_ids)
    if [ "${#retry[@]}" -gt 0 ]; then
        echo "[Cybrancee] Retrying: ${retry[*]}"
        run_steamcmd "${retry[@]}"
    fi

    mapfile -t failed < <(missing_ids)
    if [ "${#failed[@]}" -gt 0 ]; then
        echo "[Cybrancee] WARNING: could not download Workshop item(s): ${failed[*]} (private, removed or invalid ID?)" >&2
    else
        echo "[Cybrancee] All Workshop items present in $WS_CONTENT"
    fi
fi

[ "$have_cfg" -eq 1 ] || exit 0

tmp=$(mktemp "${cfg}.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

awk -v ids="$ids" '
function print_ids( i) {
    for (i=1; i<=n; i++)
        if (!seen[a[i]]++) print "ServerSubscribedWorkshopItems=" a[i]
}
BEGIN { n=split(ids,a,",") }
{
    l=tolower($0)
    sub(/\r$/, "", l)
    if (l ~ /^[ \t]*\[[^]]+\][ \t]*$/) {
        sec=l
        gsub(/^[ \t]*\[|\][ \t]*$/, "", sec)
        print
        if (sec=="onlinesubsystemsteamworks.kfworkshopsteamworks") {
            print_ids(); ws=1
        }
        if (sec=="ipdrv.tcpnetdriver") {
            drv=1
            if (!dm++) print "DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload"
        }
        next
    }
    if (sec=="onlinesubsystemsteamworks.kfworkshopsteamworks" && l ~ /^[ \t]*[+.!-]?serversubscribedworkshopitems[ \t]*=/) next
    if (sec=="ipdrv.tcpnetdriver" && l ~ /^[ \t]*[+.!-]?downloadmanagers[ \t]*=[ \t]*onlinesubsystemsteamworks\.steamworkshopdownload[ \t]*$/) next
    print
}
END {
    if (!drv) print "\n[IpDrv.TcpNetDriver]\nDownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload"
    if (!ws) { print "\n[OnlineSubsystemSteamworks.KFWorkshopSteamworks]"; print_ids() }
}' "$cfg" > "$tmp"

chmod --reference="$cfg" "$tmp"
mv -f -- "$tmp" "$cfg"
printf '[Cybrancee] Workshop IDs configured: %s\n' "$ids"