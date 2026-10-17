#!/usr/bin/env bash
# title: DNS для России в виджете сети (Yandex/DNS4EU/NextDNS вместо Cloudflare/Google)
# group: apps
# default: on
# sudo: yes
# desc: пилюли DNS в панели сети + root-helper /usr/local/bin/omarchy-dns-ru (смена DNS — через polkit-диалог)
set -euo pipefail
USER=$(whoami)
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
NETWORK_CLONE="$PLUGINS_DIR/$USER.network"
NETWORK_SRC=""

# 1. Клон виджета сети (стоковый править нельзя)
if [ ! -d "$NETWORK_CLONE" ]; then
  # Сначала пробуем штатный omarchy plugin clone (нужен живой шелл для IPC)
  if omarchy plugin clone omarchy.network 2>/dev/null; then
    : # успех
  else
    echo "dns: omarchy plugin clone не сработал (шелл не отвечает?). Копирую вручную."
    # Fallback: ищем исходный плагин и копируем файлы напрямую
    for d in /usr/share/omarchy/shell/plugins/panels/network \
             /usr/lib/omarchy/shell/plugins/panels/network; do
      [ -d "$d" ] && NETWORK_SRC="$d" && break
    done
    # Через omarchy-path
    [ -z "$NETWORK_SRC" ] && NETWORK_SRC="$(omarchy path 2>/dev/null)/shell/plugins/panels/network"
    if [ -z "$NETWORK_SRC" ] || [ ! -d "$NETWORK_SRC" ]; then
      echo "dns: не найден исходный плагин network. Попробуйте после 'omarchy restart shell'." >&2
      exit 1
    fi
    mkdir -p "$NETWORK_CLONE"
    cp -aL "$NETWORK_SRC/." "$NETWORK_CLONE/"
    # Правим manifest: меняем id на пользовательский клон
    manifest="$NETWORK_CLONE/manifest.json"
    if [ -f "$manifest" ]; then
      jq --arg id "$USER.network" --arg name "My Network" --arg src "omarchy.network" '
        .id = $id |
        .name = $name |
        if (.barWidget | type) == "object" then .barWidget.displayName = $name else . end |
        .omarchy = ((if (.omarchy | type) == "object" then .omarchy else {} end) + {clonedFrom: $src})
      ' "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"
    fi
    echo "dns: плагин network скопирован вручную в $NETWORK_CLONE"
  fi
fi

# 2. helper: копия стокового omarchy-dns с новыми провайдерами; ставится от root
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
"$RUS_DIR/dns-ru.py" helper "$tmp"
sudo install -m 0755 -o root -g root "$tmp" /usr/local/bin/omarchy-dns-ru

# 3. пилюли и вызов helper в клоне виджета
"$RUS_DIR/dns-ru.py" panel
echo "Готово: пилюли DNS — DHCP, Yandex, DNS4EU, NextDNS, Custom. Смена DNS запрашивает подтверждение (polkit)."
