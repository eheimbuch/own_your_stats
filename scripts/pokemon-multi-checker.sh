#!/usr/bin/env bash
# =============================================================================
# Pokémon Multi-Set Preorder Checker v2 (optimiert)
# =============================================================================
# Optimierungen gegenüber v1:
#   ✅ ALLE curl-Requests in EINEM curl-Prozess parallel (curl -Z --parallel-max 20)
#      → statt ~70 Shell-Forks: 0 fork-overhead, stabil, schnell
#   ✅ JSON-LD structured data ("availability") als primäre Erkennungsquelle
#   ✅ Open Graph product:availability als sekundäre Quelle
#   ✅ Keyword-Erkennung als Fallback (verbesserte Patterns)
#   ✅ Kategorie-Seiten-Guard: eBay/Tabletop Dragon brauchen Set-Keyword
#      → keine false positives wenn andere Sets gelistet sind
#   ✅ Preis-Parsing: JSON-LD first, dann sichtbarer Preis
#   ✅ History-Tracking: /tmp/pokemon-check-history.txt, Änderungen werden gemeldet
#   ✅ Fehlertoleranz: timed-out/leerer curl → NOINFO, Durchlauf läuft weiter
#   ✅ set -e entfernt (grep exit-code 1 bei No-Match ist kein Fehler)
#   ✅ Neuer Status 🛒 VERFÜGBAR (sofort kaufbar, kein Preorder)
# =============================================================================
set -uo pipefail

OUTPUT_FILE="${1:-/tmp/pokemon-check-result.txt}"
HISTORY_FILE="/tmp/pokemon-check-history.txt"
WORK_DIR=$(mktemp -d /tmp/pokemon-check-XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
PARALLEL_MAX=20       # Gleichzeitige curl-Verbindungen (curl -Z)
FETCH_TIMEOUT=18      # Sekunden pro Request

# =============================================================================
# Globale Listen: Reihenfolge für deterministische Ausgabe
# Format: "SET_ID|SHOP_NAME|URL|IS_CATEGORY_PAGE|CONTEXT_KEYWORD"
# =============================================================================
declare -a ALL_ENTRIES=()

add_shop() {
  # add_shop SET_ID SHOP_NAME URL [is_category:false] [context_kw]
  local set_id="$1" shop_name="$2" url="$3"
  local is_cat="${4:-false}" ctx="${5:-}"
  ALL_ENTRIES+=("${set_id}|${shop_name}|${url}|${is_cat}|${ctx}")
}

# =============================================================================
# SET-DEFINITIONEN
# Nur Direktlinks zu Set/Produkt-Seiten — keine generischen Suchseiten
# (außer eBay als catch-all und Tabletop Dragon Kategorie-Seiten)
# =============================================================================

# --- 30th Celebration (Release: 16.09.2026) ---
add_shop "S01_30th" "Card-Corner DE"                   "https://www.card-corner.de/pokemon-30-jahre"
add_shop "S01_30th" "Card-Corner EN"                   "https://www.card-corner.de/pokemon-30th-celebration"
add_shop "S01_30th" "Feenturm DE Display"              "https://feenturm.de/products/pokemon-tcg-30th-celebration-booster-display-de-vorbestellung"
add_shop "S01_30th" "Feenturm Ultra Premium"           "https://feenturm.de/products/pokemon-30th-celebration-ultra-premium-collection-deutsch-jetzt-vorbestellen"
add_shop "S01_30th" "CardsRfun Collection"             "https://cardsrfun.de/collections/30th-celebration"
add_shop "S01_30th" "Pokemon Center UK"                "https://www.pokemoncenter.com/en-gb/30th-celebration"
add_shop "S01_30th" "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/30th-Celebration"
add_shop "S01_30th" "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+30th+celebration&_sop=1"         "true" "30th"
add_shop "S01_30th" "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/30th-celebrations/"
add_shop "S01_30th" "Tabletop Dragon Vorbestellung"    "https://www.tabletop-dragon.de/shop_de/trading-card-games/pokemon/vorbestellung.html"   "true" "30th"
add_shop "S01_30th" "Tabletop Dragon Displays"         "https://www.tabletop-dragon.de/shop_de/trading-card-games/pokemon/booster-displays.html" "true" "30th"

# --- Pitch Black (Release: 31.07.2026) ---
add_shop "S02_PB"   "Card-Corner Pitch Black"          "https://www.card-corner.de/Pokemon-Pitch-Black"
add_shop "S02_PB"   "Card-Corner PB Display EN"        "https://www.card-corner.de/Pokemon-Pitch-Black-Display"
add_shop "S02_PB"   "Card-Corner PB ETB"               "https://www.card-corner.de/Pokemon-Pitch-Black-Elite-Trainer-Box"
add_shop "S02_PB"   "Pokemon Center UK"                "https://www.pokemoncenter.com/en-gb/search?q=pitch+black"
add_shop "S02_PB"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+pitch+black&_sacat=220"             "true" "Pitch Black"
add_shop "S02_PB"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Pitch-Black"
add_shop "S02_PB"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/pitch-black/"
add_shop "S02_PB"   "Tabletop Dragon Vorbestellung"    "https://www.tabletop-dragon.de/shop_de/trading-card-games/pokemon/vorbestellung.html"   "true" "Pitch Black"
add_shop "S02_PB"   "Tabletop Dragon Displays"         "https://www.tabletop-dragon.de/shop_de/trading-card-games/pokemon/booster-displays.html" "true" "Pitch Black"

# --- Fatale Flammen / Phantasmal Flames (14.11.2025) ---
add_shop "S03_FF"   "Card-Corner DE"                   "https://www.card-corner.de/Pokemon-Fatale-Flammen"
add_shop "S03_FF"   "Card-Corner EN"                   "https://www.card-corner.de/Pokemon-Phantasmal-Flames"
add_shop "S03_FF"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+fatale+flammen&_sacat=220"          "true" "Phantasmal"
add_shop "S03_FF"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Phantasmal-Flames"
add_shop "S03_FF"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/phantasmal-flames/"

# --- Erhabene Helden / Ascended Heroes (30.01.2026) ---
add_shop "S04_EH"   "Card-Corner DE"                   "https://www.card-corner.de/pokemon-erhabene-helden"
add_shop "S04_EH"   "Card-Corner EN"                   "https://www.card-corner.de/pokemon-ascended-heroes"
add_shop "S04_EH"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+erhabene+helden&_sacat=220"         "true" "Ascended"
add_shop "S04_EH"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Ascended-Heroes"
add_shop "S04_EH"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/ascended-heroes/"

# --- Prismatische Entwicklungen / Prismatic Evolutions (17.01.2025) ---
add_shop "S05_PE"   "Card-Corner DE"                   "https://www.card-corner.de/Prismatische-Entwicklungen-und-Prismatic-Evolutions"
add_shop "S05_PE"   "Card-Corner EN"                   "https://www.card-corner.de/Prismatic-Evolutions"
add_shop "S05_PE"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+prismatische+entwicklungen&_sacat=220" "true" "Prismatic"
add_shop "S05_PE"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Prismatic-Evolutions"
add_shop "S05_PE"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/prismatic-evolutions/"

# --- Stürmische Funken / Surging Sparks (08.11.2024) ---
add_shop "S06_SS"   "Card-Corner DE"                   "https://www.card-corner.de/stuermische-funken-und-surging-sparks"
add_shop "S06_SS"   "Card-Corner EN"                   "https://www.card-corner.de/surging-sparks"
add_shop "S06_SS"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+st%C3%BCrmische+funken&_sacat=220" "true" "Surging Sparks"
add_shop "S06_SS"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Surging-Sparks"
add_shop "S06_SS"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/surging-sparks/"

# --- Reisegefährten / Journey Together (28.03.2025) ---
add_shop "S07_JT"   "Card-Corner DE"                   "https://www.card-corner.de/reisegefaehrten-journey-together-blog"
add_shop "S07_JT"   "Card-Corner EN"                   "https://www.card-corner.de/pokemon-journey-together"
add_shop "S07_JT"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+reisegef%C3%A4hrten&_sacat=220"   "true" "Journey"
add_shop "S07_JT"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Journey-Together"
add_shop "S07_JT"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/journey-together/"

# --- Schwarze Blitze / Black Bolt (18.07.2025) ---
add_shop "S08_BB"   "Card-Corner DE"                   "https://www.card-corner.de/pokemon-schwarze-blitze"
add_shop "S08_BB"   "Card-Corner EN"                   "https://www.card-corner.de/pokemon-black-bolt-white-flare"
add_shop "S08_BB"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+schwarze+blitze&_sacat=220"        "true" "Black Bolt"
add_shop "S08_BB"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Black-Bolt"
add_shop "S08_BB"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/black-bolt/"

# --- Weiße Flammen / White Flare (18.07.2025) ---
add_shop "S09_WF"   "Card-Corner DE"                   "https://www.card-corner.de/pokemon-weisse-flammen"
add_shop "S09_WF"   "Card-Corner EN"                   "https://www.card-corner.de/pokemon-white-flare-englisch"
add_shop "S09_WF"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+wei%C3%9Fe+flammen&_sacat=220"    "true" "White Flare"
add_shop "S09_WF"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/White-Flare"
add_shop "S09_WF"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/white-flare/"

# --- Ewige Rivalen / Destined Rivals (30.05.2025) ---
add_shop "S10_ER"   "Card-Corner DE"                   "https://www.card-corner.de/pokemon-ewige-rivalen"
add_shop "S10_ER"   "Card-Corner EN"                   "https://www.card-corner.de/pokemon-destined-rivals"
add_shop "S10_ER"   "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+ewige+rivalen&_sacat=220"          "true" "Destined"
add_shop "S10_ER"   "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/Destined-Rivals"
add_shop "S10_ER"   "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/destined-rivals/"

# --- Pokemon 151 (22.09.2023) ---
add_shop "S11_151"  "Card-Corner DE"                   "https://www.card-corner.de/Pokemon-151"
add_shop "S11_151"  "eBay DE"                          "https://www.ebay.de/sch/i.html?_nkw=pokemon+151+booster&_sacat=220"            "true" "151"
add_shop "S11_151"  "Cardmarket"                       "https://www.cardmarket.com/en/Pokemon/Expansions/151"
add_shop "S11_151"  "[NL] PokeVoorraad"                "https://pokevoorraad.nl/set/151/"

# =============================================================================
# PHASE 1: curl-Config generieren & alle URLs PARALLEL fetchen
# =============================================================================
CURL_CONFIG="$WORK_DIR/curl.cfg"
> "$CURL_CONFIG"

declare -A ENTRY_FILE   # Index -> Dateipfad

for i in "${!ALL_ENTRIES[@]}"; do
  IFS='|' read -r set_id shop_name url is_cat ctx <<< "${ALL_ENTRIES[$i]}"
  outf="$WORK_DIR/${i}.html"
  ENTRY_FILE[$i]="$outf"

  # curl -K Config-Format: mehrere "url = ..." Blöcke
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

# Letztes "next" entfernen (curl mag keins am Ende)
# Eigentlich schadet es nicht, aber sauber ist sauber
head -n -1 "$CURL_CONFIG" > "${CURL_CONFIG}.tmp" && mv "${CURL_CONFIG}.tmp" "$CURL_CONFIG"

# Parallel fetch — ein einziger curl-Prozess, kein fork-bombing
curl -Z --parallel-max "$PARALLEL_MAX" -K "$CURL_CONFIG" 2>/dev/null || true

# =============================================================================
# HILFSFUNKTIONEN
# =============================================================================

extract_price() {
  local c="$1"
  local p=""

  # JSON-LD: "price": "49.99" oder "price": 49.99
  p=$(printf '%s' "$c" \
    | grep -oP '"price"\s*:\s*["\x27]?\K\d{1,4}[,.]\d{2}' 2>/dev/null \
    | head -1 || true)

  if [ -z "$p" ]; then
    # Sichtbarer Preis: €49,99 / 49,99€ / EUR 49,99
    p=$(printf '%s' "$c" \
      | grep -oP '(?:€|EUR)\s*\K\d{1,4}[,.]\d{2}|\d{1,4}[,.]\d{2}(?=\s*(?:€|EUR))' \
      2>/dev/null | head -1 || true)
  fi

  [ -n "$p" ] && echo "€$p" || echo "-"
}

analyse_page() {
  local html_file="$1"
  local context_kw="$2"
  local is_category="${3:-false}"

  # Leere oder nicht vorhandene Datei = Timeout/Server nicht erreichbar
  if [ ! -s "$html_file" ]; then
    echo "NOINFO"; return
  fi

  local c
  c=$(cat "$html_file") || { echo "NOINFO"; return; }

  # Zu kurzer Content → Error-Page, Redirect oder Bot-Block
  if [ "${#c}" -lt 300 ]; then
    echo "NOINFO"; return
  fi

  # Kategorie/Such-Seiten: Set-Keyword MUSS im Content vorkommen.
  # Verhindert false positives z.B. wenn Tabletop Dragon irgendeinen Pokemon-
  # Preorder listet, aber nicht den gesuchten Set.
  if [ "$is_category" = "true" ] && [ -n "$context_kw" ]; then
    if ! printf '%s' "$c" | grep -qiF "$context_kw" 2>/dev/null; then
      echo "NOINFO"; return
    fi
  fi

  # ---- Stufe 1: JSON-LD structured data (robustestes Signal) ----
  local jld=""
  jld=$(printf '%s' "$c" \
    | grep -oiP '"availability"\s*:\s*"?\K[^",}\s]+' 2>/dev/null \
    | head -1 | tr '[:upper:]' '[:lower:]' || true)

  case "$jld" in
    *preorder*|*vorbestell*)
      echo "PREORDER|$(extract_price "$c")"; return ;;
    *instock*|*in_stock*)
      echo "AVAILABLE|$(extract_price "$c")"; return ;;
    *outofstock*|*out_of_stock*|*discontinued*|*unavailable*)
      echo "SOLDOUT"; return ;;
  esac

  # ---- Stufe 2: Open Graph / Meta Product availability ----
  local og=""
  og=$(printf '%s' "$c" \
    | grep -oiP 'product:availability[^>]*content="\K[^"]+' 2>/dev/null \
    | head -1 | tr '[:upper:]' '[:lower:]' || true)

  case "$og" in
    *preorder*)   echo "PREORDER|$(extract_price "$c")"; return ;;
    *instock*)    echo "AVAILABLE|$(extract_price "$c")"; return ;;
    *outofstock*) echo "SOLDOUT"; return ;;
  esac

  # ---- Stufe 3: Keyword-basierte Erkennung ----
  local soldout=false preorder=false buynow=false coming=false

  # Negativ-Signal: Ausverkauft / Nicht verfügbar
  printf '%s' "$c" | grep -qiP \
    '(ausverkauft|sold[\s\-]?out|out[\s\-]of[\s\-]stock|nicht\s+lieferbar|niet\s+op\s+voorraad|uitverkocht|momenteel\s+niet\s+beschikbaar|nicht\s+verfügbar|vergriffen|nicht\s+auf\s+lager)' \
    2>/dev/null && soldout=true || true

  # Vorbestellung (Aktions-Button-Text, nicht nur "Vorbestellung" im Fließtext)
  printf '%s' "$c" | grep -qiP \
    '(vorbestellen|jetzt\s+vorbestellen|pre[\-\s]?order\s+now|pre[\-\s]?order\s+here|preorder\s+now|nu\s+pre[\-\s]?order)' \
    2>/dev/null && preorder=true || true

  # Sofort-Kauf-Signal (Produkt direkt kaufbar, kein Preorder-Kontext)
  printf '%s' "$c" | grep -qiP \
    '(in\s+den\s+warenkorb|add\s+to\s+cart|jetzt\s+kaufen|buy\s+now|in\s+winkelmand|nu\s+kopen|op\s+voorraad\s+beschikbaar|bestel\s+nu|sofort\s+lieferbar|sofort\s+verfügbar)' \
    2>/dev/null && buynow=true || true

  # Coming-soon / Noch nicht erschienen
  printf '%s' "$c" | grep -qiP \
    '(coming\s+soon|erscheint\s+am\s+\d|bald\s+verfügbar|binnenkort\s+beschikbaar|noch\s+nicht\s+erschienen|demnächst\s+verfügbar)' \
    2>/dev/null && coming=true || true

  # Entscheidungsbaum: Preorder > Kaufen > Soldout/Coming > Keine Info
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
# PHASE 2: Ergebnisse auswerten und ausgeben
# =============================================================================

# Set-Metadaten: ID -> Anzeigename
declare -A SET_LABELS
SET_LABELS["S01_30th"]="30th Celebration (Release: 16.09.2026)"
SET_LABELS["S02_PB"]="Pitch Black (Release: 31.07.2026)"
SET_LABELS["S03_FF"]="Fatale Flammen / Phantasmal Flames (14.11.2025)"
SET_LABELS["S04_EH"]="Erhabene Helden / Ascended Heroes (30.01.2026)"
SET_LABELS["S05_PE"]="Prismatische Entwicklungen / Prismatic Evolutions (17.01.2025)"
SET_LABELS["S06_SS"]="Stürmische Funken / Surging Sparks (08.11.2024)"
SET_LABELS["S07_JT"]="Reisegefährten / Journey Together (28.03.2025)"
SET_LABELS["S08_BB"]="Schwarze Blitze / Black Bolt (18.07.2025)"
SET_LABELS["S09_WF"]="Weiße Flammen / White Flare (18.07.2025)"
SET_LABELS["S10_ER"]="Ewige Rivalen / Destined Rivals (30.05.2025)"
SET_LABELS["S11_151"]="Pokemon 151 (22.09.2023)"

# Set-Reihenfolge für deterministischen Output
SET_ORDER=("S01_30th" "S02_PB" "S03_FF" "S04_EH" "S05_PE" "S06_SS" "S07_JT" "S08_BB" "S09_WF" "S10_ER" "S11_151")

# Hilfsfunktion: Alle Shops eines Sets verarbeiten → Text auf stdout
render_set() {
  local set_id="$1"
  local label="${SET_LABELS[$set_id]}"
  local new_found=false
  local -a all_found=()
  local -a all_status=()

  for i in "${!ALL_ENTRIES[@]}"; do
    IFS='|' read -r eid shop_name url is_cat ctx <<< "${ALL_ENTRIES[$i]}"
    [ "$eid" != "$set_id" ] && continue

    local html_file="${ENTRY_FILE[$i]}"
    local result
    result=$(analyse_page "$html_file" "$ctx" "$is_cat") || result="NOINFO"

    local rtype="${result%%|*}"
    local rprice="${result##*|}"
    [ "$rprice" = "$result" ] && rprice="-"   # kein | → kein Preis

    case "$rtype" in
      PREORDER)
        new_found=true
        all_found+=("✅ $shop_name — $url (Preis: $rprice)")
        all_status+=("✅ $shop_name — VORBESTELLBAR (Preis: $rprice)")
        ;;
      AVAILABLE)
        new_found=true
        all_found+=("🛒 $shop_name — $url (Preis: $rprice)")
        all_status+=("🛒 $shop_name — VERFÜGBAR/KAUFBAR (Preis: $rprice)")
        ;;
      SOLDOUT)
        all_status+=("⏳ $shop_name — Ausverkauft / Nicht verfügbar")
        ;;
      *)
        all_status+=("❓ $shop_name — Keine Info / Keine Erkennung")
        ;;
    esac
  done

  # Cron-kompatibler Output (Format MUSS gleich bleiben!)
  echo "=== $label ==="
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

# =============================================================================
# OUTPUT zusammenbauen
# =============================================================================
{
  echo "╔══════════════════════════════════════════════════╗"
  echo "║   Pokémon Multi-Set Preorder Check              ║"
  echo "║   $(date '+%d.%m.%Y %H:%M')                        ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo ""

  for set_id in "${SET_ORDER[@]}"; do
    label="${SET_LABELS[$set_id]}"
    echo "═══════════════════════════════════════════"
    echo "📦 $label"
    echo "═══════════════════════════════════════════"
    render_set "$set_id"
    echo ""
  done

  echo "╔══════════════════════════════════════════════════╗"
  echo "║   Ende des Checks                               ║"
  echo "╚══════════════════════════════════════════════════╝"

} > "$OUTPUT_FILE"

# =============================================================================
# HISTORY-TRACKING: Vergleich mit letztem Lauf
# Speichert __FOUND__/__NO_FIND__ pro Set — erkennt Statusänderungen
# =============================================================================
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

# History für nächsten Lauf speichern
echo "$current_summary" > "$HISTORY_FILE"

# Ausgabe auf stdout (damit Cron-Output sichtbar ist)
cat "$OUTPUT_FILE"
