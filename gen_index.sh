#!/usr/bin/env bash
set -euo pipefail

DIST_DIR="dist"
ASSETS_DIR="$DIST_DIR/assets"
TEMPLATE_FILE="template.index.html"
OUTPUT_FILE="$DIST_DIR/index.html"

html_escape() {
  local s="$1"

  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&#39;}"

  printf '%s' "$s"
}

url_encode() {
  local input="$1"
  local output=""
  local i char hex

  LC_ALL=C

  for (( i = 0; i < ${#input}; i++ )); do
    char="${input:i:1}"

    case "$char" in
      [a-zA-Z0-9.~_-])
        output+="$char"
        ;;
      /)
        output+="/"
        ;;
      *)
        printf -v hex '%%%02X' "'$char"
        output+="$hex"
        ;;
    esac
  done

  printf '%s' "$output"
}

if [ ! -d "$ASSETS_DIR" ]; then
  echo "Assets directory not found: $ASSETS_DIR"
  exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Template file not found: $TEMPLATE_FILE"
  exit 1
fi

files_html=""

while IFS= read -r file; do
  relative_path="${file#"$ASSETS_DIR"/}"

  href="./assets/$(url_encode "$relative_path")"
  label="$(html_escape "$relative_path")"

  files_html+="    <li>"
  files_html+=$'\n'
  files_html+="      <a href=\"$href\" target=\"_blank\" rel=\"noopener\">$label</a>"
  files_html+=$'\n'
  files_html+="    </li>"
  files_html+=$'\n'
done < <(find "$ASSETS_DIR" -type f | sort)

awk -v files="$files_html" '
{
  if ($0 == "{{FILES}}") {
    printf "%s", files
  } else {
    print
  }
}
' "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Generated $OUTPUT_FILE"
