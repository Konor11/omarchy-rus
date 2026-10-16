#!/usr/bin/env bash
# title: Поиск эмодзи по-русски
# group: ui
# default: on
# desc: добавляет русские названия к ключевым словам поиска эмодзи (клон плагина emojis)
set -euo pipefail
RUS_DIR="${RUS_DIR:-$(dirname "$(readlink -f "$0")")}"
python3 "$RUS_DIR/merge-emoji-ru.py"
