#!/bin/bash
# helpers.sh - Shared functions for bash mod scripts
#
# Usage: source from other scripts:
#   source "$(dirname "$0")/helpers.sh"

# game_build — bare game build number (e.g. "1.0.83082"). Used for <modbuild>
# in ModInfo.xml and metadata_blob on mod.io. Resolution order:
#   1. $OLDWORLD_BUILD env var (manual override — required on Linux)
#   2. macOS: $OLDWORLD_PATH/OldWorld.app/Contents/Info.plist
game_build() {
    if [ -n "$OLDWORLD_BUILD" ]; then
        echo "$OLDWORLD_BUILD"
        return 0
    fi
    if [ -z "$OLDWORLD_PATH" ]; then
        echo "Error: cannot determine game build — OLDWORLD_PATH and OLDWORLD_BUILD are both unset" >&2
        return 1
    fi
    local plist="$OLDWORLD_PATH/OldWorld.app/Contents/Info.plist"
    if [ -f "$plist" ] && [ -x /usr/libexec/PlistBuddy ]; then
        /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" | awk '{print $1}'
        return 0
    fi
    if [ -f "$plist" ]; then
        # Fallback when PlistBuddy isn't available (rare; macOS ships it)
        grep -A1 'CFBundleShortVersionString' "$plist" | tail -1 | sed -E 's@.*<string>([^ <]+).*@\1@'
        return 0
    fi
    echo "Error: cannot determine game build. Set OLDWORLD_BUILD in .env (e.g. OLDWORLD_BUILD=\"1.0.83082\")" >&2
    return 1
}

# modio_tags <modinfo_path> — comma-separated mod.io tags. Auto-derives
# Singleplayer/Multiplayer from ModInfo.xml flags, then appends $MODIO_TAGS
# from .env. Old World's mod.io taxonomy (game 634):
#   Translation, Map, Other, Multiplayer, Singleplayer, MapScript, Nation,
#   Tribe, Character, Family, GameInfo, Event, Scenario, AI, UI, Conversion
modio_tags() {
    local modinfo="$1"
    local tags=()
    grep -q '<singlePlayer>true</singlePlayer>' "$modinfo" && tags+=("Singleplayer")
    grep -q '<multiplayer>true</multiplayer>' "$modinfo" && tags+=("Multiplayer")
    if [ -n "$MODIO_TAGS" ]; then
        local extra
        IFS=',' read -ra extra <<< "$MODIO_TAGS"
        for t in "${extra[@]}"; do tags+=("$(echo "$t" | xargs)"); done
    fi
    (IFS=,; echo "${tags[*]:-}")
}

# write_modinfo_platform <staged_modinfo> <platform> <modio_id> <workshop_id> <build>
# Inject platform fields into a staged ModInfo.xml so the runtime mod loader
# can detect updates. Pass "" for fields that don't apply (e.g. workshop_id=""
# on a mod.io upload). Idempotent — strips any existing platform tags first,
# so safe on copies that may have inherited stale fields.
write_modinfo_platform() {
    local file="$1" platform="$2" modio_id="$3" workshop_id="$4" build="$5"
    local nl=$'\n'
    local insert=""
    [ -n "$platform" ]    && insert+="  <modplatform>$platform</modplatform>$nl"
    [ -n "$modio_id" ]    && insert+="  <modioID>$modio_id</modioID>$nl  <modioFileID>0</modioFileID>$nl"
    [ -n "$workshop_id" ] && insert+="  <workshopFileID>$workshop_id</workshopFileID>$nl"
    [ -n "$build" ]       && insert+="  <modbuild>$build</modbuild>$nl"

    # awk avoids BSD-vs-GNU sed divergence around \n in s/// replacements,
    # which previously emitted a literal "n" between tags on macOS. The
    # multi-line insert is passed via the environment because BSD awk rejects
    # embedded newlines in -v assignments.
    INSERT_VAL="$insert" awk '
        /<modplatform>|<modioID>|<modioFileID>|<workshopOwnerID>|<workshopFileID>|<modbuild>/ { next }
        /<\/ModInfo>/ { printf "%s", ENVIRON["INSERT_VAL"] }
        { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
