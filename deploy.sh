#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "→ Checking for JetBrains Mono Nerd Font..."
if fc-list | grep -qi "JetBrainsMono Nerd"; then
    echo "✓ Already installed"
else
    FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
    mkdir -p "$FONT_DIR"
    curl -fLo "$FONT_DIR/JetBrainsMono.tar.xz" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    tar -xf "$FONT_DIR/JetBrainsMono.tar.xz" -C "$FONT_DIR"
    rm "$FONT_DIR/JetBrainsMono.tar.xz"
    fc-cache -fv "$FONT_DIR" &>/dev/null
    echo "✓ JetBrains Mono Nerd Font installed"
fi

echo "→ Initializing submodules..."
git -C "$SCRIPT_DIR" submodule update --init
echo "✓ submodules"

echo "→ Deploying configs to $CONFIG_DIR..."
for dir in nvim tmux kitty; do
    if [ -d "$CONFIG_DIR/$dir" ]; then
        if [ -z "$(ls -A "$CONFIG_DIR/$dir")" ]; then
            # exists but empty — just remove silently
            rm -rf "$CONFIG_DIR/$dir"
            echo " removing empty config dir: "$CONFIG_DIR/$dir""
        else
            # exists and has content — ask
            read -r -p "⚠  $CONFIG_DIR/$dir already exists and is not empty. Remove and replace? [y/N] " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -rf "$CONFIG_DIR/$dir"
            else
                echo "↷ skipping $dir"
                continue
            fi
        fi
    fi
    cp -r "$SCRIPT_DIR/$dir" "$CONFIG_DIR/$dir"
    echo "✓ $dir"
done

echo ""
echo "Done! Restart Kitty, Open tmux and press prefix + I to install plugins."
echo "Remember to install lazygit"
