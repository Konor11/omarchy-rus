#!/usr/bin/env bash
# title: Язык интерфейса Omarchy — русский
# group: base
# default: on
# sudo: yes
# desc: omarchy language ru — генерирует локаль ru_RU.UTF-8, настраивает LANG и язык шелла/меню
set -euo pipefail

# Omarchy >= 3.8 имеет нативную i18n с полным русским языковым пакетом.
# Одна команда делает всё: генерирует локаль (sudo), пишет код языка
# в ~/.config/omarchy/language и настраивает session LANG через uwsm.
if omarchy language ru 2>/dev/null; then
  echo "Язык интерфейса: русский (omarchy language ru)"
else
  # Fallback для старых версий Omarchy без нативной i18n
  echo "omarchy language недоступен — настраиваю локаль вручную"
  sudo sed -i 's/^#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
  sudo locale-gen
  sudo localectl set-locale LANG=ru_RU.UTF-8
fi

# Системная раскладка клавиатуры: us,ru, переключение Left Alt + Right Alt
sudo localectl set-x11-keymap us,ru pc105 "" grp:alts_toggle 2>/dev/null || true
