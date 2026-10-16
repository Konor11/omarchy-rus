#!/usr/bin/env bash
# title: Виджет погоды: градусы Цельсия и города на русском
# group: apps
# default: on
# desc: unit=metric в shell.json + геокодинг на русском (клон плагина weather)
set -euo pipefail
RUS_DIR="${RUS_DIR:-$(dirname "$(readlink -f "$0")")}"

# 1. Метрические единицы для любого виджета погоды в раскладке бара
CFG="$HOME/.config/omarchy/shell.json"
if [ -f "$CFG" ]; then
  if ! grep -q '"unit"' "$CFG" || jq -e '.bar.layout | to_entries | map(select(.value | type == "array")) | .[].value[] | select((.id // "") | test("weather$")) | .unit' "$CFG" >/dev/null 2>&1; then
    cp "$CFG" "$CFG.bak.$(date +%s)"
    tmp=$(mktemp)
    jq '.bar.layout |= with_entries(.value |= map(
          if ((.id // "") | test("weather$")) then . + {unit: "metric"} else . end))' "$CFG" > "$tmp" \
      && mv "$tmp" "$CFG" || rm -f "$tmp"
    echo "weather: unit=metric в shell.json"
  fi
fi

# 2. Геокодинг open-meteo: language=en → language=ru
# В апстриме Omarchy это захардкожено; патчим клон плагина.
python3 - "$RUS_DIR" <<'PY'
import subprocess, sys
from pathlib import Path
rus_dir = Path(sys.argv[1])
user = subprocess.check_output(["whoami"], text=True).strip()
plugins = Path.home() / ".config/omarchy/plugins"
clone = plugins / f"{user}.weather"
panel = clone / "Panel.qml"

# Клонируем плагин, если клона нет
if not clone.exists():
    r = subprocess.run(["omarchy", "plugin", "clone", "omarchy.weather"],
                       capture_output=True, text=True)
    if r.returncode != 0 or not clone.exists():
        print(f"weather: не удалось клонировать плагин: {r.stderr.strip()}", file=sys.stderr)
        sys.exit(0)
    print("weather: плагин склонирован")

# Проверяем, не патчили ли уже
if panel.exists():
    text = panel.read_text()
    if "language=ru" in text:
        print("weather: геокодинг уже на русском")
    elif "language=en" in text:
        text = text.replace("&language=en&", "&language=ru&")
        panel.write_text(text)
        print("weather: геокодинг переключён на русский")
    else:
        print("weather: строка language=en не найдена (возможно, плагин изменился)")
PY
