#!/bin/bash
# create-mod.sh - Download and scaffold a new Old World mod
#
# Usage (interactive):
#   curl -fsSL https://raw.githubusercontent.com/becked/OldWorldModTemplate/main/create-mod.sh | bash
#
# Or download and run locally:
#   ./create-mod.sh
#
# Non-interactive (for CI / scripting):
#   MOD_NAME="My Mod" AUTHOR="Jeff" MOD_TYPE=xml ./create-mod.sh
#   MOD_NAME="My Mod" MOD_TYPE=csharp TEMPLATE_DIR=./template ./create-mod.sh

set -e

REPO="becked/OldWorldModTemplate"
BRANCH="main"
TARBALL_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"

# ── Helpers ──────────────────────────────────────────────────────────────────

prompt() {
    local var_name="$1" prompt_text="$2" default="$3"
    # If the variable is already set (via env), skip the prompt
    eval "local current_val=\"\$$var_name\""
    if [ -n "$current_val" ]; then
        return
    fi
    if [ -n "$default" ]; then
        printf "%s [%s]: " "$prompt_text" "$default" >&2
    else
        printf "%s: " "$prompt_text" >&2
    fi
    read -r value </dev/tty
    eval "$var_name=\"${value:-$default}\""
}

to_pascal_case() {
    # "My Cool Mod" → "MyCoolMod"
    echo "$1" | sed 's/[^a-zA-Z0-9 ]//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' | tr -d ' '
}

to_harmony_id() {
    local author="$1" mod="$2"
    local a=$(echo "$author" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    local m=$(echo "$mod" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    [ -z "$a" ] && a="yourname"
    echo "com.${a}.${m}"
}

# ── Interactive prompts ──────────────────────────────────────────────────────

echo ""
echo "Old World Mod Creator"
echo "====================="
echo ""

prompt MOD_NAME "Mod name" "My Mod"
prompt AUTHOR "Author name" ""

# Convert MOD_TYPE env var to the numeric choice used internally
if [ -n "$MOD_TYPE" ]; then
    case "$MOD_TYPE" in
        xml)    MOD_TYPE_CHOICE="1" ;;
        csharp) MOD_TYPE_CHOICE="2" ;;
        *)      echo "Error: MOD_TYPE must be 'xml' or 'csharp'"; exit 1 ;;
    esac
fi

if [ -z "$MOD_TYPE_CHOICE" ]; then
    echo ""
    echo "Mod type:"
    echo "  1) XML only (recommended for most mods)"
    echo "  2) XML + C# (Harmony patching)"
    printf "Choose [1]: " >&2
    read -r MOD_TYPE_CHOICE </dev/tty
    MOD_TYPE_CHOICE="${MOD_TYPE_CHOICE:-1}"
fi

# ── Download and extract template ────────────────────────────────────────────

PASCAL_NAME=$(to_pascal_case "$MOD_NAME")
FOLDER_NAME="$PASCAL_NAME"

if [ -d "$FOLDER_NAME" ]; then
    echo ""
    echo "Error: directory '$FOLDER_NAME' already exists."
    exit 1
fi

if [ -n "$TEMPLATE_DIR" ]; then
    # Local mode: copy from a local template directory (for CI / development)
    if [ ! -d "$TEMPLATE_DIR" ]; then
        echo "Error: TEMPLATE_DIR '$TEMPLATE_DIR' does not exist."
        exit 1
    fi
    echo ""
    echo "Copying template from $TEMPLATE_DIR..."
    cp -R "$TEMPLATE_DIR" "$FOLDER_NAME"
else
    echo ""
    echo "Downloading template..."

    TMPDIR_PATH=$(mktemp -d)
    trap 'rm -rf "$TMPDIR_PATH"' EXIT

    curl -fsSL "$TARBALL_URL" | tar xz -C "$TMPDIR_PATH"

    # The tarball extracts to OldWorldModTemplate-main/template/
    EXTRACTED="$TMPDIR_PATH/OldWorldModTemplate-$BRANCH/template"

    if [ ! -d "$EXTRACTED" ]; then
        echo "Error: could not find template/ in downloaded archive."
        exit 1
    fi

    mv "$EXTRACTED" "$FOLDER_NAME"
fi

# ── Configure the mod ────────────────────────────────────────────────────────

cd "$FOLDER_NAME"

# Rename gitignore → .gitignore
mv gitignore .gitignore

# ModInfo.xml
sed -i.bak "s|<displayName>My Mod Name</displayName>|<displayName>$MOD_NAME</displayName>|" ModInfo.xml
if [ -n "$AUTHOR" ]; then
    sed -i.bak "s|<author>Your Name</author>|<author>$AUTHOR</author>|" ModInfo.xml
fi
rm -f ModInfo.xml.bak

# workshop.vdf
sed -i.bak "s|\"title\".*\"My Mod Name\"|\"title\"\t\t\"$MOD_NAME\"|" workshop.vdf
rm -f workshop.vdf.bak

# CHANGELOG.md — reset to clean starting point
cat > CHANGELOG.md << 'CHANGELOG_EOF'
# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - YYYY-MM-DD

- Initial release
CHANGELOG_EOF

if [ "$MOD_TYPE_CHOICE" = "2" ]; then
    # C# mod: rename and configure
    HARMONY_ID=$(to_harmony_id "$AUTHOR" "$MOD_NAME")

    mv MyMod.csproj "$PASCAL_NAME.csproj"

    # Update .csproj
    sed -i.bak "s|<AssemblyName>MyMod</AssemblyName>|<AssemblyName>$PASCAL_NAME</AssemblyName>|" "$PASCAL_NAME.csproj"
    sed -i.bak "s|<RootNamespace>MyMod</RootNamespace>|<RootNamespace>$PASCAL_NAME</RootNamespace>|" "$PASCAL_NAME.csproj"
    rm -f "$PASCAL_NAME.csproj.bak"

    # Update ModEntryPoint.cs
    sed -i.bak "s|namespace MyMod|namespace $PASCAL_NAME|" Source/ModEntryPoint.cs
    sed -i.bak "s|com\.yourname\.mymod|$HARMONY_ID|" Source/ModEntryPoint.cs
    sed -i.bak "s|\[MyMod\]|[$PASCAL_NAME]|g" Source/ModEntryPoint.cs
    rm -f Source/ModEntryPoint.cs.bak
else
    # XML-only: remove C# files
    rm -f MyMod.csproj
    rm -rf Source/

    # Strip C#-only entries from .gitignore
    sed -i.bak '/^bin\//d; /^obj\//d' .gitignore
    rm -f .gitignore.bak
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "Created '$MOD_NAME' in ./$FOLDER_NAME/"
echo ""
echo "What's inside:"
echo "  ModInfo.xml          Mod metadata (name, author, version)"
echo "  Infos/               XML data files (bonuses, events, text, etc.)"
if [ "$MOD_TYPE_CHOICE" = "2" ]; then
echo "  Source/               C# source files (Harmony patches)"
echo "  $PASCAL_NAME.csproj   C# build configuration"
fi
echo "  scripts/             Deploy, validate, and upload scripts"
echo "  docs/                Modding guides and reference"
echo ""
echo "Next steps:"
echo "  1. cd $FOLDER_NAME"
echo "  2. Copy .env.example to .env and set OLDWORLD_MODS_PATH"
echo "  3. Add your mod content to Infos/"
echo "  4. Run ./scripts/deploy.sh to test locally"
echo ""
