#!/usr/bin/env bash
# =============================================================================
# Pokémon 30th Celebration Preorder Checker
# =============================================================================
# Überwacht deutsche & internationale Händler auf Vorbestellungen.
#
# Usage:
#   bash scripts/pokemon-30th-checker.sh
#   bash scripts/pokemon-30th-checker.sh /tmp/pokemon-30th-result.txt
#
# Cron (via Hermes Agent):
#   Alle 4h, benachrichtigt bei neuen Vorbestellungen.
#   Siehe: cron-pokemon-30th.md
# =============================================================================
set -euo pipefail

OUTPUT_FILE="${1:-/tmp/pokemon-30th-check.txt}"

# ========== ALLE GEPRÜFTEN HÄNDLER ==========

declare -A SHOPS

# === Deutsche Händler ===
SHOPS["Amazon DE (Suche)"]="https://www.amazon.de/s?k=Pokemon+30th+Celebration"
SHOPS["Müller Spielzeug"]="https://www.mueller.de/spielzeug/pokemon/"
SHOPS["Smyths Toys DE"]="https://www.smythstoys.com/de/de-de/spielzeug/action-spielzeug/pok%C3%A9mon/pok%C3%A9mon-karten/c/SM1001013002"
SHOPS["MediaMarkt (Pokémon)"]="https://www.mediamarkt.de/de/category/pok%C3%A9mon-karten-1356075.html"
SHOPS["Saturn (Pokémon)"]="https://www.saturn.de/de/category/pok%C3%A9mon-karten-1356075.html"
SHOPS["OTTO (Pokémon Karten)"]="https://www.otto.de/suchergebnis/?q=pokemon+karten+30+jubilaeum"

# === Spezialisierte TCG-Shops ===
SHOPS["Card-Corner DE"]="https://www.card-corner.de/pokemon-30-jahre"
SHOPS["Card-Corner EN"]="https://www.card-corner.de/pokemon-30th-celebration"
SHOPS["Feenturm DE Vorbestellung"]="https://feenturm.de/products/pokemon-tcg-30th-celebration-booster-display-de-vorbestellung"
SHOPS["YONKO TCG JP Display"]="https://yonko-tcg.de/products/jp-pokemon-display-30th-celebration-m6a"
SHOPS["YONKO TCG Futuristic Box"]="https://yonko-tcg.de/products/jp-pokemon-box-30th-celebration-futuristic-box"
SHOPS["Pokitrio JP Display"]="https://www.pokitrio.de/products/preorder-pokemon-30th-celebration-m6a-display-japanisch"
SHOPS["Pokitrio JP Illustration"]="https://www.pokitrio.de/products/preorder-pokemon-30th-celebration-illustration-collection-first-partner-japanisch"

# === Offizielle Kanäle ===
SHOPS["Pokemon Center US"]="https://www.pokemoncenter.com/30th-celebration/"
SHOPS["Pokemon Center ETB"]="https://www.pokemon.com/us/pokemon-tcg/product-gallery/30th-celebration-pokemon-center-elite-trainer-box"
SHOPS["Pokemon.com TCG Seite"]="https://tcg.pokemon.com/en-us/expansions/30th-celebration/"

# === International ===
SHOPS["Amazon JP Futuristic Box"]="https://www.amazon.co.jp/-/en/Pokemon-Card-Game-CELEBRATION-FUTURISTIC/dp/B0H4C7VPS4"
SHOPS["Amazon JP Booster Box"]="https://www.amazon.co.jp/-/en/dp/B0H4B79HYR"
SHOPS["Cardmarket (30th)"]="https://www.cardmarket.com/en/Pokemon/Expansions/30th-Celebration"

# === eBay ===
SHOPS["eBay DE (30th)"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+30th+celebration&_sop=1"

# ========== CHECK-LOGIK ==========

NEW_PREORDERS=false
declare -a PREORDER_SHOPS=()
declare -a ALL_STATUS=()

UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

for shop_name in "${!SHOPS[@]}"; do
  url="${SHOPS[$shop_name]}"
  [ -z "$url" ] && continue

  content=$(curl -sL --max-time 15 -A "$UA" --compressed "$url" 2>/dev/null || true)

  has_preorder=false
  has_soldout=false

  # Preorder/Vorbestellung/Available indicators
  if echo "$content" | grep -qiP '(vorbestellen|vorbestellung|pre.?order|pre.?order|add.to.cart|in.den.warenkorb|jetzt.kaufen|auf.lager|verfügbar|lieferbar|auf.vorrat|in.stock|jetzt.bestellen|sofort.verfügbar|sofort.käuflich|zahlungsarten|kaufen)'; then
    has_preorder=true
  fi

  # Sold out / unavailable / coming soon indicators
  if echo "$content" | grep -qiP '(ausverkauft|sold.out|nicht.verfügbar|coming.soon|bald.verfügbar|benachrichtigen|notify.me|out.of.stock|erscheint.am|currently.unavailable|temporär.nicht.verfügbar|derzeit.nicht.verfügbar|momentan.nicht|nicht.lieferbar|zurzeit.nicht|demnächst|nicht.auf.lager)'; then
    has_soldout=true
  fi

  price=$(echo "$content" | grep -oP '(€\s*\d+[.,]\d{2}|\$\s*\d+[.,]\d{2}|EUR\s*\d+[.,]\d{2}|\d+[.,]\d{2}\s*€|\d+[.,]\d{2}\s*EUR|\d+[.,]\d{2}\s*¥)' | head -3 | tr '\n' ' | ' || echo "k.A.")

  if [ "$has_preorder" = true ] && [ "$has_soldout" = false ]; then
    NEW_PREORDERS=true
    PREORDER_SHOPS+=("✅ $shop_name — Preis: $price $url")
    ALL_STATUS+=("✅ $shop_name — VORBESTELLBAR (Preis: $price)")
  elif [ "$has_soldout" = true ]; then
    ALL_STATUS+=("⏳ $shop_name — Ausverkauft / Bald verfügbar")
  else
    ALL_STATUS+=("❓ $shop_name — Kein klarer Vorbestellungsstatus")
  fi

  sleep 0.3
done

# ========== AUSGABE ==========

{
  echo "=== Pokémon 30th Celebration Preorder-Check ==="
  echo "Datum: $(date '+%d.%m.%Y %H:%M')"
  echo "Release: 16. September 2026"
  echo "Geprüfte Shops: ${#SHOPS[@]}"
  echo ""
  echo "=== NEUE Vorbestellungen ==="
  if [ "$NEW_PREORDERS" = true ]; then
    for s in "${PREORDER_SHOPS[@]}"; do
      echo "$s"
    done
  else
    echo "Keine neuen Vorbestellungen entdeckt."
  fi
  echo ""
  echo "=== Alle Shop-Status ==="
  for s in "${ALL_STATUS[@]}"; do
    echo "$s"
  done
  echo ""
  echo "Hinweise:"
  echo "- Amazon DE/OTTO/Müller/MM/Saturn nehmen Vorbestellungen oft erst 4-6 Wochen vor Release auf"
  echo "- JP Vorbestellungen (Amazon JP, YONKO, Pokitrio) sind teilweise bereits möglich"
  echo "- Pokémon Center PC ETB: exklusive Variante, limitiert!"
} > "$OUTPUT_FILE"

cat "$OUTPUT_FILE"
echo ""

# JSON summary for downstream automation
jq -n \
  --arg has_new "$NEW_PREORDERS" \
  --argjson total "${#SHOPS[@]}" \
  --arg checked "$(date '+%Y-%m-%dT%H:%M:%S%z')" \
  '{has_new_preorders: ($has_new == "true"), total_shops: $total, checked_at: $checked}' 2>/dev/null || echo '{"has_new_preorders":false,"total_shops":0}'