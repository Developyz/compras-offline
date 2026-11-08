"""Genera el asset para bases NUEVAS desde los SQL oficiales. Python estándar."""
import json
import sqlite3
from pathlib import Path

raiz = Path(__file__).resolve().parents[2]
with sqlite3.connect(':memory:') as db:
    for archivo in ['DB/sqlite.sql', 'DB/migrations/sqlite-v002.sql',
                    'DB/migrations/sqlite-v003.sql', 'DB/migrations/sqlite-v004.sql']:
        db.executescript((raiz / archivo).read_text())
    assert not db.execute('PRAGMA foreign_key_check').fetchall()
    sentencias = [r[0] for r in db.execute(
        "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL "
        "AND type IN ('table','index') AND name NOT LIKE 'sqlite_%' "
        "ORDER BY CASE type WHEN 'table' THEN 0 ELSE 1 END, name")]
    for version in [2, 3, 4]:
        sentencias.append("INSERT INTO versiones_esquema VALUES "
                          f"({version},strftime('%Y-%m-%dT%H:%M:%fZ','now'))")
    destino = raiz / 'android/assets/db/esquema_v4.json'
    destino.write_text(json.dumps(sentencias, ensure_ascii=False, indent=2) + '\n')
    tablas = db.execute("SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchone()[0]
    print(f'{len(sentencias)} sentencias; {tablas} tablas; {destino.name}')

(raiz / "android/assets/db/unidades_iniciales.json").write_text((raiz / "DB/unidades-iniciales.json").read_text())
