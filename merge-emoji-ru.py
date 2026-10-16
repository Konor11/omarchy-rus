#!/usr/bin/env python3
"""Добавляет русские названия к ключевым словам поиска эмодзи.

Поиск эмодзи в Omarchy работает по полю `k` в emojis.json (английские ключевые слова).
Этот скрипт клонирует плагин emojis и дописывает русские названия (CLDR) к полю `k`,
чтобы эмодзи можно было искать по-русски: «рука», «сердце», «грусть» и т.д.

Интерфейс плагина (placeholder, «нет совпадений») переводится нативной i18n Omarchy.

Использование:
  merge-emoji-ru.py           склонировать и добавить ключевые слова
  merge-emoji-ru.py --check   проверить, нужно ли обновить
"""
import getpass
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
USER = getpass.getuser()
PLUGINS_DIR = Path.home() / ".config/omarchy/plugins"
EMOJIS_RU = HERE / "data" / "emojis-ru.json"


def ensure_clone() -> Path | None:
    target = PLUGINS_DIR / f"{USER}.emojis"
    if target.exists():
        return target
    r = subprocess.run(["omarchy", "plugin", "clone", "omarchy.emojis"],
                       capture_output=True, text=True)
    if r.returncode != 0 or not target.exists():
        print(f"merge-emoji-ru: не удалось клонировать плагин emojis: {r.stderr.strip()}",
              file=sys.stderr)
        return None
    print("merge-emoji-ru: плагин emojis склонирован")
    return target


def merge(target: Path) -> int:
    f = target / "emojis.json"
    if not f.exists() or not EMOJIS_RU.exists():
        print("merge-emoji-ru: emojis.json или emojis-ru.json не найден", file=sys.stderr)
        return 1
    ru = json.loads(EMOJIS_RU.read_text())
    items = json.loads(f.read_text())
    added = 0
    for item in items:
        name = ru.get(item.get("e", ""))
        if name and name not in item.get("k", ""):
            item["k"] = (item.get("k", "") + " " + name).strip()
            added += 1
    if added:
        f.write_text(json.dumps(items, ensure_ascii=False, separators=(",", ":")))
    print(f"merge-emoji-ru: добавлены русские ключевые слова к {added} эмодзи")
    return 0


def main() -> int:
    if "--check" in sys.argv:
        target = PLUGINS_DIR / f"{USER}.emojis"
        if not target.exists():
            print("merge-emoji-ru: клон плагина emojis не найден")
            return 1
        # Проверяем, есть ли русские ключевые слова
        f = target / "emojis.json"
        if not f.exists():
            return 1
        items = json.loads(f.read_text())
        has_ru = any(any(ord(c) > 0x400 and ord(c) < 0x500 for c in item.get("k", ""))
                     for item in items)
        print("merge-emoji-ru: " + ("русские ключевые слова есть" if has_ru
              else "русских ключевых слов нет, запустите merge-emoji-ru.py"))
        return 0 if has_ru else 1

    target = ensure_clone()
    if not target:
        return 1
    return merge(target)


if __name__ == "__main__":
    sys.exit(main())
