#!/usr/bin/env bash
# title: Раскладка US/RU в Hyprland
# group: base
# default: on
# desc: добавляет us,ru в ~/.config/hypr/input.lua (с резервной копией) и перезагружает Hyprland
set -euo pipefail
INPUT_LUA="$HOME/.config/hypr/input.lua"
MARK="-- omarchy-rus: layouts"
if ! grep -qF -- "$MARK" "$INPUT_LUA"; then
  cp "$INPUT_LUA" "$INPUT_LUA.Bak.$(date +%s)"
  cat >> "$INPUT_LUA" <<'LUA'

-- omarchy-rus: layouts
hl.config({
  input = {
    kb_layout = "us,ru",
    kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
  },
})
LUA
  hyprctl reload
  hyprctl configerrors
fi
