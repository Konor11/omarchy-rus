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
    # Сначала пробуем штатный clone (нужен живой шелл для IPC)
    r = subprocess.run(["omarchy", "plugin", "clone", "omarchy.emojis"],
                       capture_output=True, text=True)
    if r.returncode == 0 and target.exists():
        print("merge-emoji-ru: плагин emojis склонирован")
        return target
    # Fallback: копируем вручную
    print(f"merge-emoji-ru: omarchy plugin clone не сработал, копирую вручную")
    import shutil
    src = None
    for d in ["/usr/share/omarchy/shell/plugins/emojis",
              "/usr/lib/omarchy/shell/plugins/emojis"]:
        if Path(d).exists():
            src = Path(d)
            break
    if not src:
        r2 = subprocess.run(["omarchy", "path"], capture_output=True, text=True)
        if r2.returncode == 0:
            src = Path(r2.stdout.strip()) / "shell/plugins/emojis"
    if not src or not src.exists():
        print(f"merge-emoji-ru: исходный плагин emojis не найден", file=sys.stderr)
        return None
    target.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, target, dirs_exist_ok=True)
    # Правим manifest
    manifest = target / "manifest.json"
    if manifest.exists():
        import json as _json
        m = _json.loads(manifest.read_text())
        m["id"] = f"{USER}.emojis"
        m["name"] = "My Emojis"
        m.setdefault("omarchy", {})["clonedFrom"] = "omarchy.emojis"
        manifest.write_text(_json.dumps(m, ensure_ascii=False, indent=2))
    print(f"merge-emoji-ru: плагин emojis скопирован вручную")
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
