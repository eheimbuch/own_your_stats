# Pokémon Multi-Set Preorder Checker — Cron

## Aktiver Cron-Job (Stand Juli 2026)

**Name:** `Pokemon Multi-Set Checker`
**Job-ID:** `4ff2f9f02b13`
**Schedule:** `0 7,9,11,13,15,16,17,19,21,23 * * *` (alle 2h, 7-23 Uhr)
**Script:** `scripts/pokemon-multi-checker.sh`
**Lieferung:** `origin` (Telegram DM)

## Cron-Job neu erstellen (falls nötig)

```bash
hermes cron create \
  --name "Pokemon Multi-Set Checker" \
  --schedule "0 7,9,11,13,15,16,17,19,21,23 * * *" \
  --deliver origin \
  --script pokemon-30th-check.sh \
  --toolsets terminal,file \
  --prompt 'Du bist mein Pokémon Vorbestellungs- und Verfügbarkeits-Wächter für MEHRERE Sets.

AUFGABE JEDEN CHECK:
1. Führe aus: bash /root/.hermes/scripts/pokemon-multi-checker.sh /tmp/pokemon-check-result.txt
2. Lies die Ergebnisdatei: /tmp/pokemon-check-result.txt

Die Ausgabe ist in Blöcke unterteilt, einer pro Set. Jeder Block hat entweder __FOUND__ (verfügbar) oder __NO_FIND__ (nichts).

REGELN:
- Wenn ALLE Sets __NO_FIND__ haben → antworte mit: "✅ Nix Neues — nächster Check in 2h."
- Wenn EIN ODER MEHRERE Sets __FOUND__ haben → ALARM! Für JEDES gefundene Set:
  • Set-Name
  • Welche Shops verfügbar sind + Preise
  • Direktlinks
  • Kauftipp: Fairer Preis oder überteuert?
  • "JETZT ZUSCHLAGEN!" wenn lohnenswert

Keine Doppelalarme für gleiche Shops wie beim letzten Mal.

Übersicht aller 11 Sets:
1. 30th Celebration (Release 16.09.2026) — ⭐ WICHTIGSTES SET
2. Pitch Black (Release 31.07.2026)
3. Fatale Flammen / Phantasmal Flames (14.11.2025)
4. Erhabene Helden / Ascended Heroes (30.01.2026)
5. Prismatische Entwicklungen / Prismatic Evolutions (17.01.2025)
6. Stürmische Funken / Surging Sparks (08.11.2024)
7. Reisegefährten / Journey Together (28.03.2025)
8. Schwarze Blitze / Black Bolt (18.07.2025)
9. Weiße Flammen / White Flare (18.07.2025)
10. Ewige Rivalen / Destined Rivals (30.05.2025)
11. Pokemon 151 (22.09.2023)

Heute ist der 2. Juli 2026.'
```

## Überwachte Shops

### Kommende Sets (30th, Pitch Black) — 25+ Shops pro Set
- Card-Corner DE & EN, Feenturm, YONKO TCG, Pokitrio
- Pokémon Center US, Pokemon.com, Amazon JP
- Cardmarket, eBay DE
- **NL:** PokeVoorraad, Bol, Amazon NL, Intertoys, Spellenhuis
- **NEU:** Gate to the Games, CardsRfun, Cardcosmos, LD Cards, Sapphire Cards, Starz Collectibles, TCGViert

### Erschienene Sets — 5-6 Kern-Shops pro Set
- Card-Corner, eBay, Cardmarket, PokeVoorraad

## Script-Pfad

- Repo: `scripts/pokemon-multi-checker.sh`
- Hermes: `~/.hermes/scripts/pokemon-30th-check.sh` (Cron erwartet diesen Namen)