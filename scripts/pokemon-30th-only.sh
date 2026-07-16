#!/usr/bin/env bash
# =============================================================================
# Pokémon 30th Celebration Only Checker — maximale Shop-Abdeckung
# =============================================================================
# Nur das 30th Celebration Set (Release: 16.09.2026) mit maximal vielen Shops.
# Paralleler curl (curl -Z) für Geschwindigkeit.
# =============================================================================
set -uo pipefail

OUTPUT_FILE="${1:-/tmp/pokemon-30th-result.txt}"
WORK_DIR=$(mktemp -d /tmp/pokemon-30th-XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
FETCH_TIMEOUT=18

declare -a ALL_ENTRIES=()

add_shop() {
  local set_id="$1" shop_name="$2" url="$3"
  local is_cat="${4:-false}" ctx="${5:-}"
  ALL_ENTRIES+=("${set_id}|${shop_name}|${url}|${is_cat}|${ctx}")
}

# =============================================================================
# 30TH CELEBRATION — MAXIMALE ABDECKUNG (~40 Shops)
# =============================================================================

# --- Direkte Produktseiten (DE) ---
add_shop "30TH" "Card-Corner DE (30 Jahre)"          "https://www.card-corner.de/pokemon-30-jahre"
add_shop "30TH" "Card-Corner EN (30th Celebration)"  "https://www.card-corner.de/pokemon-30th-celebration"
add_shop "30TH" "Feenturm DE Display"                "https://feenturm.de/products/pokemon-tcg-30th-celebration-booster-display-de-vorbestellung"
add_shop "30TH" "Feenturm Ultra Premium"             "https://feenturm.de/products/pokemon-30th-celebration-ultra-premium-collection-deutsch-jetzt-vorbestellen"
add_shop "30TH" "Feenturm ETB"                       "https://feenturm.de/products/pokemon-30th-celebration-elite-trainer-box-deutsch-vorbestellung"
add_shop "30TH" "CardsRfun Collection"               "https://cardsrfun.de/collections/30th-celebration"
add_shop "30TH" "CardsRfun UPC"                      "https://cardsrfun.de/products/30th-celebration-ultra-premium-collection"
add_shop "30TH" "GeeksHeaven DE"                     "https://geeksheaven.de/collections/pokemon-30-jahre-30th-celebration"
add_shop "30TH" "GeeksHeaven EN"                     "https://geeksheaven.de/collections/30th-celebration"
add_shop "30TH" "Gate to the Games (Vorverkauf)"     "https://www.gate-to-the-games.de/Vorverkauf/?q=30th+Celebration+Pokemon"
add_shop "30TH" "Cardcosmos"                         "https://cardcosmos.de/search?q=30th+Celebration+Pokemon&type=product"
add_shop "30TH" "LD Cards & More"                    "https://ldcardsandmore.com/search?q=30th+Celebration+Pokemon&type=product"
add_shop "30TH" "Sapphire Cards"                     "https://sapphire-cards.de/search?q=30th+Celebration+Pokemon&type=product"
add_shop "30TH" "Starz Collectibles"                 "https://starzcollectibles.de/collections/30th-celebration"
add_shop "30TH" "TCGViert"                           "https://tcgviert.com/collections/30th-celebration"
add_shop "30TH" "TCGViert Mini Tin"                  "https://tcgviert.com/products/pokemon-tcg-mini-tin-30th-celebration-en-random-limit-2-person-preorder-02-10-2026-beschreibung-lesen"
add_shop "30TH" "Cardmex"                            "https://cardmex-shop.de/collections/30-jahre-30th-celebration"
add_shop "30TH" "PHD Games"                          "https://www.phdgames.com/?s=30th+Celebration+Pokemon&type=product"
add_shop "30TH" "Pokitrio DE"                        "https://www.pokitrio.de/collections/30th-celebration"
add_shop "30TH" "YONKO TCG (DE)"                     "https://yonko-tcg.de/collections/30th-celebration"
add_shop "30TH" "YONKO TCG JP Display"               "https://yonko-tcg.de/products/jp-pokemon-display-30th-celebration-m6a"
add_shop "30TH" "TCG Love"                           "https://tcg-love.de/produkt-kategorie/pokemon/30th-celebration/"
add_shop "30TH" "Universe TCG (EU)"                  "https://www.universetcg.com/collections/pokemon-30th-celebration"

# --- Internationale Direkt-Shops ---
add_shop "30TH" "Pokemon Center DE"                  "https://www.pokemoncenter.com/de-de/category/30th-celebration"
add_shop "30TH" "Pokemon Center UK"                  "https://www.pokemoncenter.com/en-gb/30th-celebration"
add_shop "30TH" "Pokemon Center US"                  "https://www.pokemoncenter.com/en-us/30th-celebration"
add_shop "30TH" "Pokemon Center PC ETB"              "https://www.pokemoncenter.com/product/10-10447-111/pokemon-tcg-30th-celebration-pokemon-center-elite-trainer-box"

# --- Amazon (Kategoriesuche) ---
add_shop "30TH" "Amazon DE"                          "https://www.amazon.de/s?k=Pokemon+30th+Celebration" "true" "30th"
add_shop "30TH" "Amazon NL"                          "https://www.amazon.nl/s?k=Pokemon+30th+Celebration" "true" "30th"

# --- Marktplätze & Preisvergleiche ---
add_shop "30TH" "Cardmarket"                         "https://www.cardmarket.com/en/Pokemon/Expansions/30th-Celebration"
add_shop "30TH" "eBay DE"                            "https://www.ebay.de/sch/i.html?_nkw=pokemon+30th+celebration&_sop=1" "true" "30th"
add_shop "30TH" "eBay UK"                            "https://www.ebay.co.uk/sch/i.html?_nkw=pokemon+30th+celebration&_sop=1" "true" "30th"
add_shop "30TH" "TCGCheck DE (30 Jahre)"             "https://www.tcgcheck.de/pokemon/set/de/30-jahre/index"
add_shop "30TH" "TCGCheck EN (30th Celebration)"     "https://www.tcgcheck.de/pokemon/set/en/30th-celebration/index"

# --- NL Shops ---
add_shop "30TH" "[NL] PokeVoorraad"                  "https://pokevoorraad.nl/set/30th-celebrations/"
add_shop "30TH" "[NL] Bol.com"                       "https://www.bol.com/nl/nl/s?searchtext=pokemon+30th+celebration" "true" "30th"
add_shop "30TH" "[NL] Intertoys"                     "https://www.intertoys.nl/zoeken?q=pokemon+30th+celebration" "true" "30th"
add_shop "30TH" "[NL] Spellenhuis"                   "https://www.spellenhuis.nl/zoeken?q=pokemon+30th+celebration" "true" "30th"
add_shop "30TH" "[NL] Games en Zo"                   "https://www.gamesenzo.nl/zoeken?q=30th+celebration+pokemon" "true" "30th"
add_shop "30TH" "[NL] Card Barn"                     "https://www.cardbarn.nl/zoeken?q=pokemon+30th+celebration" "true" "30th"

# --- CH/AT Shops ---
add_shop "30TH" "[CH] MaRo Games"                    "https://maro-games.ch/search?q=30th+Celebration+Pokemon&type=product"
add_shop "30TH" "[CH] Pokécado"                      "https://www.pokecado.ch/en/collections/30th-celebration-kollektion-pokemon-tcg"
add_shop "30TH" "[AT] SpielRaum"                     "https://www.spielraum.co.at/de/catalogsearch/result/?q=pokemon+30th+celebration" "true" "30th"

# --- UK/EU Online-Shops ---
add_shop "30TH" "[UK] Chaos Cards"                   "https://www.chaoscards.co.uk/search?q=30th+celebration+pokemon" "true" "30th"
add_shop "30TH" "[UK] Magic Madhouse"                "https://www.magicmadhouse.co.uk/search?q=30th+celebration+pokemon" "true" "30th"
add_shop "30TH" "[UK] Total Cards"                   "https://www.totalcards.net/search?q=30th+celebration+pokemon" "true" "30th"
add_shop "30TH" "[UK] Cardmarket UK"                 "https://www.cardmarket.com/en/Pokemon/Expansions/30th-Celebration"
add_shop "30TH" "[FR] Ludifolie"                     "https://www.ludifolie.com/recherche?q=pokemon+30th+celebration" "true" "30th"
add_shop "30TH" "[FR] Pokemon France"                "https://www.pokemon.com/fr/jcc/30th-celebration"
add_shop "30TH" "[IT] Goblin Gaming"                 "https://www.goblingaming.it/search?q=pokemon+30th+celebration" "true" "30th"
add_shop "30TH" "[ES] TCG Singles Spain"             "https://www.tcgsingles.es/busqueda?q=30th+celebration+pokemon" "true" "30th"
add_shop "30TH" "[BE] Card Galaxy"                   "https://www.cardgalaxy.be/search?q=30th+celebration+pokemon" "true" "30th"

# --- Preisaggregatoren (tracken 290+ EU-Shops live) ---
add_shop "30TH" "TCGRadar 30th Pack"                 "https://tcgradar.eu/tracker/30th-celebration-pack"
add_shop "30TH" "TCGRadar 30th Booster Bundle"       "https://tcgradar.eu/de/tracker/30th-celebration-booster-bundle"
add_shop "30TH" "TCGRadar Classic Pack"              "https://tcgradar.eu/tracker/30th-celebration-classic-collection-pack"
add_shop "30TH" "TCGRadar Guide"                     "https://tcgradar.eu/guides/30th-celebration"

# --- Tabletop Dragon (Kategorieseiten) ---
add_shop "30TH" "Tabletop Dragon Vorbestellung"      "https://www.tabletop-dragon.de/shop_de/trading-card-games/pokemon/vorbestellung.html" "true" "30th"
add_shop "30TH" "Tabletop Dragon Displays"           "https://www.tabletop-dragon.de/shop_de/trading-card-games/pokemon/booster-displays.html" "true" "30th"

echo "[INFO] ${#ALL_ENTRIES[@]} Shops für 30th Celebration registriert" >&2

# =============================================================================
# PHASE 1: Parallel curl
# =============================================================================
CURL_CONFIG="$WORK_DIR/curl.cfg"
> "$CURL_CONFIG"

declare -A ENTRY_FILE

for i in "${!ALL_ENTRIES[@]}"; do
  IFS='|' read -r set_id shop_name url is_cat ctx <<< "${ALL_ENTRIES[$i]}"
  outf="$WORK_DIR/${i}.html"
  ENTRY_FILE[$i]="$outf"

  {
    printf 'url = "%s"\n' "$url"
    printf 'output = "%s"\n' "$outf"
    printf 'max-time = %d\n' "$FETCH_TIMEOUT"
    printf 'silent\n'
    printf 'location\n'
    printf 'compressed\n'
    printf 'user-agent = "%s"\n' "$UA"
    printf 'header = "Accept: text/html,application/xhtml+xml,*/*;q=0.8"\n'
    printf 'header = "Accept-Language: de-DE,de;q=0.9,en-US;q=0.7,nl;q=0.5"\n'
    printf 'header = "Referer: https://www.google.de/"\n'
    printf 'next\n'
  } >> "$CURL_CONFIG"
done

# Letztes "next" entfernen
head -n -1 "$CURL_CONFIG" > "${CURL_CONFIG}.tmp" && mv "${CURL_CONFIG}.tmp" "$CURL_CONFIG"

echo "[INFO] Fetche ${#ALL_ENTRIES[@]} URLs parallel..." >&2
curl -Z --parallel-max 30 -K "$CURL_CONFIG" 2>/dev/null || true

# =============================================================================
# HILFSFUNKTIONEN
# =============================================================================

extract_price() {
  local c="$1" p=""
  p=$(printf '%s' "$c" | grep -oP '"price"\s*:\s*["\x27]?\K\d{1,4}[,.]\d{2}' 2>/dev/null | head -1 || true)
  if [ -z "$p" ]; then
    p=$(printf '%s' "$c" | grep -oP '(?:€|EUR|£|USD)\s*\K\d{1,4}[,.]\d{2}|\d{1,4}[,.]\d{2}(?=\s*(?:€|EUR|£|USD))' 2>/dev/null | head -1 || true)
  fi
  [ -n "$p" ] && echo "€$p" || echo "-"
}

analyse_page() {
  local html_file="$1" context_kw="$2" is_category="${3:-false}"

  if [ ! -s "$html_file" ]; then echo "NOINFO"; return; fi
  local c; c=$(cat "$html_file") || { echo "NOINFO"; return; }
  if [ "${#c}" -lt 300 ]; then echo "NOINFO"; return; fi

  if [ "$is_category" = "true" ] && [ -n "$context_kw" ]; then
    if ! printf '%s' "$c" | grep -qiF "$context_kw" 2>/dev/null; then
      echo "NOINFO"; return
    fi
  fi

  # JSON-LD
  local jld=""
  jld=$(printf '%s' "$c" | grep -oiP '"availability"\s*:\s*"?\K[^",}\s]+' 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]' || true)
  case "$jld" in
    *preorder*|*vorbestell*) echo "PREORDER|$(extract_price "$c")"; return ;;
    *instock*|*in_stock*)    echo "AVAILABLE|$(extract_price "$c")"; return ;;
    *outofstock*|*out_of_stock*|*discontinued*|*unavailable*) echo "SOLDOUT"; return ;;
  esac

  # OG Meta
  local og=""
  og=$(printf '%s' "$c" | grep -oiP 'product:availability[^>]*content="\K[^"]+' 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]' || true)
  case "$og" in
    *preorder*) echo "PREORDER|$(extract_price "$c")"; return ;;
    *instock*)  echo "AVAILABLE|$(extract_price "$c")"; return ;;
    *outofstock*) echo "SOLDOUT"; return ;;
  esac

  # Keywords
  local soldout=false preorder=false buynow=false coming=false

  printf '%s' "$c" | grep -qiP '(ausverkauft|sold[\s\-]?out|out[\s\-]of[\s\-]stock|nicht\s+lieferbar|niet\s+op\s+voorraad|uitverkocht|momenteel\s+niet\s+beschikbaar|nicht\s+verfügbar|vergriffen|nicht\s+auf\s+lager|out\s+of\s+stock|currently\s+unavailable|notification\s+only)' 2>/dev/null && soldout=true || true
  printf '%s' "$c" | grep -qiP '(vorbestellen|jetzt\s+vorbestellen|pre[\-\s]?order\s+now|pre[\-\s]?order\s+here|preorder\s+now|nu\s+pre[\-\s]?order|preorder\s+yours|order\s+now\s+for\s+release|reserve\s+yours|add\s+to\s+cart|in\s+den\s+warenkorb|jetzt\s+kaufen|buy\s+now|in\s+winkelmand|nu\s+kopen|op\s+voorraad|bestel\s+nu|sofort\s+lieferbar|sofort\s+verfügbar|add\s+to\s+basket|in\s+stock|available\s+now)' 2>/dev/null && preorder=true || true
  printf '%s' "$c" | grep -qiP '(coming\s+soon|erscheint\s+am\s+\d|bald\s+verfügbar|binnenkort\s+beschikbaar|noch\s+nicht\s+erschienen|demnächst\s+verfügbar)' 2>/dev/null && coming=true || true

  if $preorder && ! $soldout; then
    echo "PREORDER|$(extract_price "$c")"
  elif $buynow && ! $soldout; then
    echo "AVAILABLE|$(extract_price "$c")"
  elif $soldout || $coming; then
    echo "SOLDOUT"
  else
    echo "NOINFO"
  fi
}

# =============================================================================
# PHASE 2: Auswertung
# =============================================================================

HISTORY_FILE="/tmp/pokemon-30th-history.txt"

new_found=false
declare -a found_items=()
declare -a status_items=()

for i in "${!ALL_ENTRIES[@]}"; do
  IFS='|' read -r eid shop_name url is_cat ctx <<< "${ALL_ENTRIES[$i]}"
  html_file="${ENTRY_FILE[$i]}"
  result=$(analyse_page "$html_file" "$ctx" "$is_cat") || result="NOINFO"

  rtype="${result%%|*}"
  rprice="${result##*|}"
  [ "$rprice" = "$result" ] && rprice="-"

  case "$rtype" in
    PREORDER)
      new_found=true
      found_items+=("✅ $shop_name — $url (Preis: $rprice)")
      status_items+=("✅ $shop_name — VORBESTELLBAR (Preis: $rprice)")
      ;;
    AVAILABLE)
      new_found=true
      found_items+=("🛒 $shop_name — $url (Preis: $rprice)")
      status_items+=("🛒 $shop_name — VERFÜGBAR/KAUFBAR (Preis: $rprice)")
      ;;
    SOLDOUT)
      status_items+=("⏳ $shop_name — Ausverkauft / Nicht verfügbar")
      ;;
    *)
      status_items+=("❓ $shop_name — Keine Info / Keine Erkennung")
      ;;
  esac
done

# Output
{
  echo "╔══════════════════════════════════════════════════╗"
  echo "║   Pokémon 30th Celebration Only Check           ║"
  echo "║   $(date '+%d.%m.%Y %H:%M')                        ║"
  echo "║   ${#ALL_ENTRIES[@]} Shops gecheckt                     ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo ""
  echo "═══════════════════════════════════════════"
  echo "🎂 30th Celebration (Release: 16.09.2026)"
  echo "═══════════════════════════════════════════"
  echo "=== 30th Celebration (Release: 16.09.2026) ==="
  if [ "$new_found" = true ]; then
    echo "__FOUND__"
    for r in "${found_items[@]}"; do echo "  $r"; done
    echo "__STATUSES__"
    for s in "${status_items[@]}"; do echo "  $s"; done
  else
    echo "__NO_FIND__"
    echo "__STATUSES__"
    for s in "${status_items[@]}"; do echo "  $s"; done
  fi
  echo "___ENDSET___"
  echo ""
  echo "╔══════════════════════════════════════════════════╗"
  echo "║   Ende des Checks                               ║"
  echo "╚══════════════════════════════════════════════════╝"
} > "$OUTPUT_FILE"

# History-Comparison
current_summary=$(grep -E "^(=== |__FOUND__|__NO_FIND__)" "$OUTPUT_FILE" 2>/dev/null || true)

if [ -f "$HISTORY_FILE" ] && [ -s "$HISTORY_FILE" ]; then
  previous_summary=$(cat "$HISTORY_FILE")
  if [ "$current_summary" != "$previous_summary" ]; then
    {
      echo ""
      echo "⚡ ══════════════════════════════════════════════"
      echo "⚡ ÄNDERUNGEN SEIT LETZTEM CHECK:"
      echo "⚡ ══════════════════════════════════════════════"
      diff <(echo "$previous_summary") <(echo "$current_summary") \
        | grep "^[<>]" \
        | sed 's/^< /  VORHER: /; s/^> /  JETZT:  /' \
        || true
      echo "⚡ ══════════════════════════════════════════════"
    } >> "$OUTPUT_FILE"
  fi
fi
echo "$current_summary" > "$HISTORY_FILE"

cat "$OUTPUT_FILE"