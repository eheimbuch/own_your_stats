# Pokémon 30th Celebration — Preorder Checker Cron

## Hermes Cron-Job Befehl

Einmalig ausführen um den Cron zu aktivieren:

```bash
hermes cron create \
  --name "Pokemon 30th Preorder Checker" \
  --schedule "every 4h" \
  --deliver origin \
  --script pokemon-30th-check.sh \
  --toolsets terminal,file \
  --prompt 'Du bist mein Pokemon 30th Celebration Vorbestellungs-Wächter.

AUFGABE JEDEN CHECK:
1. Führe aus: bash /root/own_your_stats/scripts/pokemon-30th-checker.sh /tmp/pokemon-30th-result.txt 
2. Lies die Ergebnisdatei: /tmp/pokemon-30th-result.txt

REGELN:
- Wenn "Keine neuen Vorbestellungen entdeckt" → antworte mit: "✅ Stillstand — nächster Check in 4h."
- Wenn ein Shop mit ✅ "VORBESTELLBAR" gemeldet wird → ALARM! Schreib eine DETAILIERTE Nachricht:
  • Welche Shops
  • Preise
  • Direktlinks
  • Kauftipp (UVP: DE Display ~150€, ETB ~55-65€, JP Display ~80-100€)
  • Sag "JETZT ZUSCHLAGEN!" wenn Preis fair ist

WICHTIG: Wenn der gleiche Shop wie beim letzten Mal noch verfügbar ist, nicht nochmal alarmieren.
Heute ist der 1. Juli 2026. Release ist der 16. September 2026.'
```

## Oder per JSON (via GitHub API / deploy)

```json
{
  "name": "Pokemon 30th Preorder Checker",
  "schedule": "every 4h",
  "deliver": "origin",
  "script": "pokemon-30th-check.sh",
  "enabled_toolsets": ["terminal", "file"],
  "prompt": "Du bist mein Pokemon 30th Celebration Vorbestellungs-Wächter..."
}
```

## Script-Pfad

Das Script liegt unter: `scripts/pokemon-30th-checker.sh`

Für den Hermes-Cron muss es zusätzlich in `~/.hermes/scripts/pokemon-30th-check.sh` kopiert werden (der Cron erwartet es dort).