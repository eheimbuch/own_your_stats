#!/usr/bin/env bash
# =============================================================================
# Pokémon Multi-Set Preorder Checker
# =============================================================================
# Überwacht mehrere Sets gleichzeitig bei deutschen & niederländischen Händlern.
#
# Usage:
#   bash /root/.hermes/scripts/pokemon-multi-checker.sh
#   bash /root/.hermes/scripts/pokemon-multi-checker.sh /tmp/pokemon-check-result.txt
#
# Cron (via Hermes Agent):
#   Alle 2h (7-23 Uhr), benachrichtigt bei neuen Vorbestellungen.
# =============================================================================
set -euo pipefail

OUTPUT_FILE="${1:-/tmp/pokemon-check-result.txt}"

UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

# ========== HILFSFUNKTION: Shops checken ==========
# Aufruf: check_set "Set-Name" shops_assoc_array
check_set() {
  local set_name="$1"
  local -n shops_ref=$2
  local new_found=false
  local all_found=()
  local all_status=()

  while IFS=$'\x1f' read -r shop_name shop_url; do
    [ -z "$shop_name" ] && continue

    content=$(curl -sL --max-time 12 -A "$UA" --compressed "$shop_url" 2>/dev/null || true)

    has_avail=false
    has_soldout=false

    if echo "$content" | grep -qiP \
      '(vorbestellen|vorbestellung|pre.?order|add.to.cart|in.den.warenkorb|jetzt.kaufen|auf.lager|verfügbar|lieferbar|in.stock|bestellen|kopen|bestel|op.voorraad|beschikbaar|leverbaar|in.winkelmand|nu.kopen)'; then
      has_avail=true
    fi

    if echo "$content" | grep -qiP \
      '(ausverkauft|sold.out|nicht.verfügbar|coming.soon|erscheint.am|bald.verfügbar|nicht.lieferbar|out.of.stock|niet.op.voorraad|uitverkocht|binnenkort.beschikbaar|momenteel.niet)'; then
      has_soldout=true
    fi

    price=$(echo "$content" | grep -oP '(€\s*\d+[.,]?\d{2}|\$\s*\d+[.,]?\d{2})' | head -3 | tr '\n' ' | ' || echo "")
    [ -z "$price" ] && price="-"

    if $has_avail && ! $has_soldout; then
      new_found=true
      all_found+=("✅ $shop_name — $shop_url (Preis: $price)")
      all_status+=("✅ $shop_name — VORBESTELLBAR (Preis: $price)")
    elif $has_soldout; then
      all_status+=("⏳ $shop_name — Ausverkauft / Bald verfügbar")
    else
      all_status+=("❓ $shop_name — Keine Info")
    fi

    sleep 0.2
  done < <(for key in "${!shops_ref[@]}"; do printf '%s\x1f%s\n' "$key" "${shops_ref[$key]}"; done)

  # Ausgabe
  echo "=== $set_name ==="
  if [ "$new_found" = true ]; then
    echo "__FOUND__"
    for r in "${all_found[@]}"; do echo "  $r"; done
    echo "__STATUSES__"
    for s in "${all_status[@]}"; do echo "  $s"; done
  else
    echo "__NO_FIND__"
    echo "__STATUSES__"
    for s in "${all_status[@]}"; do echo "  $s"; done
  fi
  echo "___ENDSET___"
}

# ========== SET-DEFINITIONEN ==========

# --- 30th Celebration (Release: 16.09.2026) — NUR DE/EN ---
declare -A S30
S30["Card-Corner DE"]="https://www.card-corner.de/pokemon-30-jahre"
S30["Card-Corner EN"]="https://www.card-corner.de/pokemon-30th-celebration"
S30["Feenturm DE Vorbestellung"]="https://feenturm.de/products/pokemon-tcg-30th-celebration-booster-display-de-vorbestellung"
S30["Feenturm Ultra Premium"]="https://feenturm.de/products/pokemon-30th-celebration-ultra-premium-collection-deutsch-jetzt-vorbestellen"
S30["Cardmarket"]="https://www.cardmarket.com/en/Pokemon/Expansions/30th-Celebration"
S30["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+30th+celebration&_sop=1"
S30["[NL] PokeVoorraad"]="https://pokevoorraad.nl/set/30th-celebrations/"
S30["[NL] Bol.com Suche"]="https://www.bol.com/nl/nl/s/?searchtext=30th+celebration+pokemon"
S30["[NL] Amazon NL"]="https://www.amazon.nl/s?k=Pokemon+30th+Celebration"
S30["[NL] Intertoys"]="https://www.intertoys.nl/zoeken?q=30th+celebration+pokemon"
S30["[NL] Spellenhuis"]="https://www.spellenhuis.nl/zoeken?search=30th+celebration+pokemon"

# --- Pitch Black (Release: 31.07.2026) — NUR DE/EN ---
declare -A SPB
SPB["Card-Corner Pitch Black"]="https://www.card-corner.de/Pokemon-Pitch-Black"
SPB["Card-Corner PB Display EN"]="https://www.card-corner.de/Pokemon-Pitch-Black-Display"
SPB["Card-Corner PB ETB"]="https://www.card-corner.de/Pokemon-Pitch-Black-Elite-Trainer-Box"
SPB["Feenturm Suche"]="https://feenturm.de/search?q=pitch+black+pokemon&type=product"
SPB["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+pitch+black&_sacat=220"
SPB["Cardmarket"]="https://www.cardmarket.com/en/Pokemon/Expansions/Pitch-Black"
SPB["[NL] PokeVoorraad"]="https://pokevoorraad.nl/set/pitch-black/"
SPB["[NL] Bol.com Suche"]="https://www.bol.com/nl/nl/s/?searchtext=pitch+black+pokemon"
SPB["[NL] Amazon NL Suche"]="https://www.amazon.nl/s?k=Pitch+Black+Pokemon"
SPB["[NL] Intertoys Suche"]="https://www.intertoys.nl/zoeken?q=pitch+black+pokemon"

# --- Fatale Flammen / Phantasmal Flames (Release: 14.11.2025) - erschienen ---
declare -A SFF
SFF["Card-Corner DE (Fatale Flammen)"]="https://www.card-corner.de/Pokemon-Fatale-Flammen"
SFF["Card-Corner EN (Phantasmal Flames)"]="https://www.card-corner.de/Pokemon-Phantasmal-Flames"
SFF["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+fatale+flammen&_sacat=220"
SFF["Cardmarket (Phantasmal Flames)"]="https://www.cardmarket.com/en/Pokemon/Expansions/Phantasmal-Flames"
SFF["[NL] PokeVoorraad (Phantasmal)"]="https://pokevoorraad.nl/set/phantasmal-flames/"

# --- Erhabene Helden / Ascended Heroes (Release: 30.01.2026) - erschienen ---
declare -A SEH
SEH["Card-Corner DE (Erhabene Helden)"]="https://www.card-corner.de/pokemon-erhabene-helden"
SEH["Card-Corner EN (Ascended Heroes)"]="https://www.card-corner.de/pokemon-ascended-heroes"
SEH["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+erhabene+helden&_sacat=220"
SEH["Cardmarket (Ascended Heroes)"]="https://www.cardmarket.com/en/Pokemon/Expansions/Ascended-Heroes"
SEH["[NL] PokeVoorraad (Ascended)"]="https://pokevoorraad.nl/set/ascended-heroes/"

# --- Prismatische Entwicklungen / Prismatic Evolutions (Release: 17.01.2025) - erschienen ---
declare -A SPE
SPE["Card-Corner DE (Prismatische)"]="https://www.card-corner.de/Prismatische-Entwicklungen-und-Prismatic-Evolutions"
SPE["Card-Corner EN (Prismatic)"]="https://www.card-corner.de/Prismatic-Evolutions"
SPE["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+prismatische+entwicklungen&_sacat=220"
SPE["Cardmarket (Prismatic Evolutions)"]="https://www.cardmarket.com/en/Pokemon/Expansions/Prismatic-Evolutions"
SPE["[NL] PokeVoorraad (Prismatic)"]="https://pokevoorraad.nl/set/prismatic-evolutions/"

# --- Stürmische Funken / Surging Sparks (Release: 08.11.2024) - erschienen ---
declare -A SSF
SSF["Card-Corner DE (Stürmische Funken)"]="https://www.card-corner.de/stuermische-funken-und-surging-sparks"
SSF["Card-Corner EN (Surging Sparks)"]="https://www.card-corner.de/surging-sparks"
SSF["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+st%C3%BCrmische+funken&_sacat=220"
SSF["Cardmarket (Surging Sparks)"]="https://www.cardmarket.com/en/Pokemon/Expansions/Surging-Sparks"
SSF["[NL] PokeVoorraad (Surging)"]="https://pokevoorraad.nl/set/surging-sparks/"

# --- Reisegefährten / Journey Together (Release: 28.03.2025) - erschienen ---
declare -A SJT
SJT["Card-Corner DE (Reisegefährten)"]="https://www.card-corner.de/reisegefaehrten-journey-together-blog"
SJT["Card-Corner EN (Journey Together)"]="https://www.card-corner.de/pokemon-journey-together"
SJT["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+reisegef%C3%A4hrten&_sacat=220"
SJT["Cardmarket (Journey Together)"]="https://www.cardmarket.com/en/Pokemon/Expansions/Journey-Together"
SJT["[NL] PokeVoorraad (Journey)"]="https://pokevoorraad.nl/set/journey-together/"

# --- Schwarze Blitze / Black Bolt (Release: 18.07.2025) - erschienen ---
declare -A SBB
SBB["Card-Corner DE (Schwarze Blitze)"]="https://www.card-corner.de/pokemon-schwarze-blitze"
SBB["Card-Corner EN (Black Bolt)"]="https://www.card-corner.de/pokemon-black-bolt-white-flare"
SBB["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+schwarze+blitze&_sacat=220"
SBB["Cardmarket (Black Bolt)"]="https://www.cardmarket.com/en/Pokemon/Expansions/Black-Bolt"
SBB["[NL] PokeVoorraad (Black Bolt)"]="https://pokevoorraad.nl/set/black-bolt/"

# --- Weiße Flammen / White Flare (Release: 18.07.2025) - erschienen ---
declare -A SWF
SWF["Card-Corner DE (Weiße Flammen)"]="https://www.card-corner.de/pokemon-weisse-flammen"
SWF["Card-Corner EN (White Flare)"]="https://www.card-corner.de/pokemon-white-flare-englisch"
SWF["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+wei%C3%9Fe+flammen&_sacat=220"
SWF["Cardmarket (White Flare)"]="https://www.cardmarket.com/en/Pokemon/Expansions/White-Flare"
SWF["[NL] PokeVoorraad (White Flare)"]="https://pokevoorraad.nl/set/white-flare/"

# --- Ewige Rivalen / Destined Rivals (Release: 30.05.2025) - erschienen ---
declare -A SER
SER["Card-Corner DE (Ewige Rivalen)"]="https://www.card-corner.de/pokemon-ewige-rivalen"
SER["Card-Corner EN (Destined Rivals)"]="https://www.card-corner.de/pokemon-destined-rivals"
SER["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+ewige+rivalen&_sacat=220"
SER["Cardmarket (Destined Rivals)"]="https://www.cardmarket.com/en/Pokemon/Expansions/Destined-Rivals"
SER["[NL] PokeVoorraad (Destined)"]="https://pokevoorraad.nl/set/destined-rivals/"

# --- Pokemon 151 (Release: 22.09.2023) - erschienen ---
declare -A S151
S151["Card-Corner DE (151)"]="https://www.card-corner.de/Pokemon-151"
S151["eBay DE"]="https://www.ebay.de/sch/i.html?_nkw=pokemon+151+booster&_sacat=220"
S151["Cardmarket (151)"]="https://www.cardmarket.com/en/Pokemon/Expansions/151"
S151["[NL] PokeVoorraad (151)"]="https://pokevoorraad.nl/set/151/"

# ========== GENERISCHE ZUSATZ-SHOPS (für ALLE Sets) ==========
# Amazon DE + Pokemon Center UK für JEDES Set
add_de_shops() {
  local -n target=$1
  local search_term="$2"
  local encoded="${search_term// /+}"
  
  target["Amazon DE Suche"]="https://www.amazon.de/s?k=${encoded}&i=toys"
  target["Pokemon Center UK"]="https://www.pokemoncenter.com/en-gb/search?q=${encoded}"
}

add_de_shops S30 "Pokemon+30th+Celebration"
add_de_shops SPB "Pitch+Black+Pokemon"
add_de_shops SFF "Fatale+Flammen+Pokemon"
add_de_shops SEH "Erhabene+Helden+Pokemon"
add_de_shops SPE "Prismatische+Entwicklungen+Pokemon"
add_de_shops SSF "Stürmische+Funken+Pokemon"
add_de_shops SJT "Reisegefährten+Pokemon"
add_de_shops SBB "Schwarze+Blitze+Pokemon"
add_de_shops SWF "Weiße+Flammen+Pokemon"
add_de_shops SER "Ewige+Rivalen+Pokemon"
add_de_shops S151 "Pokemon+151+Set"

# ========== NEUE GENERISCHE SHOPS (nur für TOP-Sets) ==========
# Diese Shops werden per Such-URL nur in die wichtigsten/wertvollsten Sets eingebunden
add_cross_shops() {
  local -n target=$1
  local search_term="$2"
  local encoded="${search_term// /+}"
  
  target["Gate to the Games"]="https://www.gate-to-the-games.de/Vorverkauf/?q=${encoded}"
  target["CardsRfun"]="https://cardsrfun.de/search?q=${encoded}&type=product"
  target["Cardcosmos"]="https://cardcosmos.de/search?q=${encoded}"
  target["LD Cards & More"]="https://ldcardsandmore.com/search?q=${encoded}&type=product"
  target["Sapphire Cards"]="https://sapphire-cards.de/search?q=${encoded}&type=product"
  target["Starz Collectibles"]="https://starzcollectibles.de/search?q=${encoded}&type=product"
  target["TCGViert"]="https://tcgviert.com/search?q=${encoded}&type=product"
}

# Cross-Shops nur für 30th + Pitch Black (kommende/wichtige Sets)
add_cross_shops S30 "30th+Celebration+Pokemon"
add_cross_shops SPB "Pitch+Black+Pokemon"

# ========== HAUPTLOGIK ==========

{
  echo "╔══════════════════════════════════════════════════╗"
  echo "║   Pokémon Multi-Set Preorder Check              ║"
  echo "║   $(date '+%d.%m.%Y %H:%M')                        ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo ""

  # 1) 30th Celebration
  echo "═══════════════════════════════════════════"
  echo "📦 30th Celebration (Release: 16.09.2026)"
  echo "═══════════════════════════════════════════"
  check_set "30th Celebration" S30
  echo ""

  # 2) Pitch Black
  echo "═══════════════════════════════════════════"
  echo "📦 Pitch Black (Release: 31.07.2026)"
  echo "═══════════════════════════════════════════"
  check_set "Pitch Black" SPB
  echo ""

  # 3) Fatale Flammen
  echo "═══════════════════════════════════════════"
  echo "📦 Fatale Flammen / Phantasmal Flames (14.11.2025)"
  echo "═══════════════════════════════════════════"
  check_set "Fatale Flammen" SFF
  echo ""

  # 4) Erhabene Helden
  echo "═══════════════════════════════════════════"
  echo "📦 Erhabene Helden / Ascended Heroes (30.01.2026)"
  echo "═══════════════════════════════════════════"
  check_set "Erhabene Helden" SEH
  echo ""

  # 5) Prismatische Entwicklungen
  echo "═══════════════════════════════════════════"
  echo "📦 Prismatische Entwicklungen / Prismatic Evolutions (17.01.2025)"
  echo "═══════════════════════════════════════════"
  check_set "Prismatische Entwicklungen" SPE
  echo ""

  # 6) Stürmische Funken
  echo "═══════════════════════════════════════════"
  echo "📦 Stürmische Funken / Surging Sparks (08.11.2024)"
  echo "═══════════════════════════════════════════"
  check_set "Stürmische Funken" SSF
  echo ""

  # 7) Reisegefährten
  echo "═══════════════════════════════════════════"
  echo "📦 Reisegefährten / Journey Together (28.03.2025)"
  echo "═══════════════════════════════════════════"
  check_set "Reisegefährten" SJT
  echo ""

  # 8) Schwarze Blitze
  echo "═══════════════════════════════════════════"
  echo "📦 Schwarze Blitze / Black Bolt (18.07.2025)"
  echo "═══════════════════════════════════════════"
  check_set "Schwarze Blitze" SBB
  echo ""

  # 9) Weiße Flammen
  echo "═══════════════════════════════════════════"
  echo "📦 Weiße Flammen / White Flare (18.07.2025)"
  echo "═══════════════════════════════════════════"
  check_set "Weiße Flammen" SWF
  echo ""

  # 10) Ewige Rivalen
  echo "═══════════════════════════════════════════"
  echo "📦 Ewige Rivalen / Destined Rivals (30.05.2025)"
  echo "═══════════════════════════════════════════"
  check_set "Ewige Rivalen" SER
  echo ""

  # 11) Pokemon 151
  echo "═══════════════════════════════════════════"
  echo "📦 Pokemon 151 (22.09.2023)"
  echo "═══════════════════════════════════════════"
  check_set "Pokemon 151" S151
  echo ""

  echo "╔══════════════════════════════════════════════════╗"
  echo "║   Ende des Checks                               ║"
  echo "╚══════════════════════════════════════════════════╝"

} > "$OUTPUT_FILE"

cat "$OUTPUT_FILE"