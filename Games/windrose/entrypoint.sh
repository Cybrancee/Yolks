#!/bin/bash
# Windrose Dedicated Server - Cybrancee

SERVER_BASE="/home/container/R5"
SERVER_DESC="$SERVER_BASE/ServerDescription.json"
SAVES_BASE="$SERVER_BASE/Saved/SaveProfiles/Default"
STATE_FILE="$SERVER_BASE/Saved/windrose_active_world.txt"

# Snapshot directory — inside Saved so it survives container recreations.
# Used ONLY when the file is missing or corrupt, not as a general restore.
SNAPSHOT_DIR="$SERVER_BASE/Saved/entrypoint_snapshots"
SERVER_DESC_SNAP="$SNAPSHOT_DIR/ServerDescription.json.snap"
WORLD_DESC_SNAP="$SNAPSHOT_DIR/WorldDescription.json.snap"

log() { echo "[Windrose] $*"; }

is_valid_id() {
    [[ "${#1}" -eq 32 ]] && [[ "$1" =~ ^[a-fA-F0-9]{32}$ ]]
}

is_valid_json() {
    [ -f "$1" ] && jq empty "$1" 2>/dev/null
}

jq_patch() {
    local file="$1" path="$2" type="$3" value="$4" desc="$5"

    if [ ! -f "$file" ]; then
        log "  - $file not found, skipping: $desc"
        return
    fi

    local tmp
    tmp=$(mktemp)

    case "$type" in
        string)
            if jq --arg v "$value" "$path = \$v" "$file" > "$tmp" 2>/dev/null; then
                mv "$tmp" "$file" && log "  + $desc"
            else
                rm -f "$tmp"; log "  ! ERROR: jq failed -- $desc"
            fi
            ;;
        number)
            if jq --arg v "$value" "$path = (\$v | tonumber)" "$file" > "$tmp" 2>/dev/null; then
                mv "$tmp" "$file" && log "  + $desc"
            else
                rm -f "$tmp"; log "  ! ERROR: jq failed -- $desc"
            fi
            ;;
        boolean)
            if jq "$path = $value" "$file" > "$tmp" 2>/dev/null; then
                mv "$tmp" "$file" && log "  + $desc"
            else
                rm -f "$tmp"; log "  ! ERROR: jq failed -- $desc"
            fi
            ;;
        *)
            rm -f "$tmp"; log "  ! ERROR: unknown type '$type' -- $desc"
            ;;
    esac
}

# -----------------------------------------------------------------------
# disaster_recovery — restore snapshot ONLY if the file is missing or corrupt.
# Does NOT restore on kill/crash because Pterodactyl's targeted JSON parser
# preserves all non-panel fields even after a kill, so there's nothing to recover.
# -----------------------------------------------------------------------
disaster_recovery() {
    # ServerDescription.json
    if ! is_valid_json "$SERVER_DESC"; then
        if [ -f "$SERVER_DESC_SNAP" ]; then
            log "Recovery: ServerDescription.json missing/corrupt -- restoring snapshot"
            cp "$SERVER_DESC_SNAP" "$SERVER_DESC"
        else
            log "Recovery: ServerDescription.json missing and no snapshot exists -- first boot"
        fi
    fi

    # WorldDescription.json for the active world
    if [ -n "$ACTIVE_WORLD_ID" ] && [ -f "$WORLD_DESC_SNAP" ]; then
        local wdir world_desc
        wdir=$(find_worlds_dir)
        world_desc="$wdir/$ACTIVE_WORLD_ID/WorldDescription.json"
        if ! is_valid_json "$world_desc"; then
            log "Recovery: WorldDescription.json missing/corrupt -- restoring snapshot"
            mkdir -p "$(dirname "$world_desc")"
            cp "$WORLD_DESC_SNAP" "$world_desc"
        fi
    fi
}

# -----------------------------------------------------------------------
# snapshot_configs — taken right before launching Windrose.
# Captures the "ideal" corrected state so we can recover if the file
# gets deleted or corrupted on disk.
# NOT used to restore after kills -- see disaster_recovery above.
# -----------------------------------------------------------------------
snapshot_configs() {
    mkdir -p "$SNAPSHOT_DIR"

    if is_valid_json "$SERVER_DESC"; then
        cp "$SERVER_DESC" "$SERVER_DESC_SNAP"
        log "Snapshot: ServerDescription.json saved"
    else
        log "Snapshot: ServerDescription.json invalid -- skipping"
    fi

    local wdir world_desc
    wdir=$(find_worlds_dir)
    if [ -n "$ACTIVE_WORLD_ID" ] && is_valid_id "$ACTIVE_WORLD_ID"; then
        world_desc="$wdir/$ACTIVE_WORLD_ID/WorldDescription.json"
        if is_valid_json "$world_desc"; then
            cp "$world_desc" "$WORLD_DESC_SNAP"
            log "Snapshot: WorldDescription.json saved (world $ACTIVE_WORLD_ID)"
        fi
    fi
}

# -----------------------------------------------------------------------
# apply_panel_settings
# Patches only the panel-managed fields in ServerDescription.json.
# All other fields (UserSelectedRegion, UseDirectConnection, etc.) are
# left exactly as-is -- whether the user edited them or Windrose wrote them.
# -----------------------------------------------------------------------
apply_panel_settings() {
    log "Applying panel settings to ServerDescription.json..."

    if [ -n "${SERVER_NAME:-}" ]; then
        jq_patch "$SERVER_DESC" \
            '.ServerDescription_Persistent.ServerName' \
            string "$SERVER_NAME" \
            "ServerName = $SERVER_NAME"
    fi

    if [ -n "${MAX_PLAYERS:-}" ]; then
        jq_patch "$SERVER_DESC" \
            '.ServerDescription_Persistent.MaxPlayerCount' \
            number "$MAX_PLAYERS" \
            "MaxPlayerCount = $MAX_PLAYERS"
    fi

    if [ -n "${IS_PASSWORD_PROTECTED:-}" ]; then
        local bool_val
        if [[ "$IS_PASSWORD_PROTECTED" == "1" || "$IS_PASSWORD_PROTECTED" == "true" ]]; then
            bool_val="true"
        else
            bool_val="false"
        fi
        jq_patch "$SERVER_DESC" \
            '.ServerDescription_Persistent.IsPasswordProtected' \
            boolean "$bool_val" \
            "IsPasswordProtected = $bool_val"
    fi

    if [ -n "${PASSWORD:-}" ]; then
        jq_patch "$SERVER_DESC" \
            '.ServerDescription_Persistent.Password' \
            string "$PASSWORD" \
            "Password = (set)"
    fi

    # InviteCode -- only write if the panel has a value.
    # If blank, leave whatever is in the file (server-generated code).
    if [ -n "${INVITE_CODE:-}" ]; then
        jq_patch "$SERVER_DESC" \
            '.ServerDescription_Persistent.InviteCode' \
            string "$INVITE_CODE" \
            "InviteCode = $INVITE_CODE"
    else
        log "  - InviteCode not set in panel -- keeping file value"
    fi
}

# -----------------------------------------------------------------------
# update_json_world_id
# -----------------------------------------------------------------------
update_json_world_id() {
    local id="$1"
    jq_patch "$SERVER_DESC" \
        '.ServerDescription_Persistent.WorldIslandId' \
        string "$id" \
        "WorldIslandId = $id"
}

# -----------------------------------------------------------------------
# World directory discovery -- handles RocksDB path changes across versions
# -----------------------------------------------------------------------
find_worlds_dir() {
    local candidate
    for candidate in \
        "$SAVES_BASE/RocksDB_v2/0.10.0/Worlds" \
        "$SAVES_BASE/RocksDB/0.10.0/Worlds" ; do
        [ -d "$candidate" ] && echo "$candidate" && return
    done
    local found
    found=$(find "$SAVES_BASE" -maxdepth 3 -type d -name "Worlds" 2>/dev/null | head -1)
    [ -n "$found" ] && echo "$found" && return
    echo "$SAVES_BASE/RocksDB_v2/0.10.0/Worlds"  # default for first boot
}

# -----------------------------------------------------------------------
# find_active_world -- sets ACTIVE_WORLD_ID
# Priority: state file -> panel env var -> oldest world folder on disk
# -----------------------------------------------------------------------
find_active_world() {
    ACTIVE_WORLD_ID=""
    WORLDS_DIR=$(find_worlds_dir)
    log "Worlds directory: $WORLDS_DIR"

    if [ -f "$STATE_FILE" ]; then
        local stored
        stored=$(tr -d '[:space:]' < "$STATE_FILE")
        if is_valid_id "$stored" && [ -d "$WORLDS_DIR/$stored" ]; then
            log "Persisted world: $stored"
            ACTIVE_WORLD_ID="$stored"
            return
        fi
        log "Persisted world '$stored' not on disk -- removing stale state"
        rm -f "$STATE_FILE"
    fi

    local env_id="${WORLD_ISLAND_ID:-}"
    if is_valid_id "$env_id" && [ -d "$WORLDS_DIR/$env_id" ]; then
        log "Panel env var world: $env_id"
        ACTIVE_WORLD_ID="$env_id"
        return
    fi

    if [ -d "$WORLDS_DIR" ]; then
        local id count
        id=$(ls -tr "$WORLDS_DIR" 2>/dev/null | grep -E '^[a-fA-F0-9]{32}$' | head -1)
        if is_valid_id "$id"; then
            count=$(ls "$WORLDS_DIR" 2>/dev/null | grep -cE '^[a-fA-F0-9]{32}$')
            log "Auto-detected oldest world: $id (${count} world(s) on disk)"
            if [ "$count" -gt 1 ]; then
                log "WARNING: $count worlds found -- extras may be from the WorldID bug."
                log "Using oldest (your original). Safe to delete extras via file manager:"
                ls -tr "$WORLDS_DIR" 2>/dev/null | grep -E '^[a-fA-F0-9]{32}$' | while read -r w; do
                    [ "$w" = "$id" ] && log "  [KEEP]  $w" || log "  [EXTRA] $w"
                done
            fi
            ACTIVE_WORLD_ID="$id"
            return
        fi
    fi

    log "No existing world -- server will create one on first start"
}

# -----------------------------------------------------------------------
# monitor_and_save_new_world -- background job for first-boot world capture
# -----------------------------------------------------------------------
monitor_and_save_new_world() {
    log "Monitoring for first world creation (up to 10 min)..."
    local elapsed=0 interval=10 max=600
    while (( elapsed < max )); do
        sleep "$interval"
        elapsed=$(( elapsed + interval ))
        local wdir id
        wdir=$(find_worlds_dir)
        if [ -d "$wdir" ]; then
            id=$(ls "$wdir" 2>/dev/null | grep -E '^[a-fA-F0-9]{32}$' | head -1)
            if is_valid_id "$id"; then
                ACTIVE_WORLD_ID="$id"
                echo "$id" > "$STATE_FILE"
                log "First world saved to state file: $id"
                log "This world will be loaded automatically on every future restart."
                return
            fi
        fi
    done
    log "WARNING: No world appeared within ${max}s -- check server logs"
}

# =======================================================================
# MAIN
# =======================================================================

log "============================================"
log "  Windrose Dedicated Server"
log "============================================"

mkdir -p "$SAVES_BASE"

# Step 1: Resolve which world to load
find_active_world

# Step 2: Disaster recovery -- only if file is missing or corrupt.
# Normal kills/crashes: Pterodactyl's targeted parser already preserved
# non-panel fields on disk, nothing to recover.
disaster_recovery

# Step 3: Patch panel fields on top of whatever is on disk.
# Non-panel fields (UserSelectedRegion, UseDirectConnection, etc.) are untouched.
apply_panel_settings

# Step 4: Lock in the WorldIslandId -- always last, always wins.
if [ -n "$ACTIVE_WORLD_ID" ]; then
    update_json_world_id "$ACTIVE_WORLD_ID"
    echo "$ACTIVE_WORLD_ID" > "$STATE_FILE"
    log "World locked: $ACTIVE_WORLD_ID"
else
    monitor_and_save_new_world &
    MONITOR_PID=$!
fi

# Step 5: Snapshot the corrected state BEFORE launching.
# If the file gets deleted or corrupted, disaster_recovery can use this.
snapshot_configs

# Step 6: Launch the server
log "Launching Windrose Server..."
sleep 2
wine /home/container/R5/Binaries/Win64/WindroseServer-Win64-Shipping.exe -Log &
WR_PID=$!

tail --retry -c0 -F /home/container/R5/Saved/Logs/R5.log --pid=$WR_PID
wait "$WR_PID"

[ -n "${MONITOR_PID:-}" ] && kill "$MONITOR_PID" 2>/dev/null || true
