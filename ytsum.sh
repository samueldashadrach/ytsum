#!/usr/bin/env bash

# written by o3

# Summarise a YouTube video with OpenAI “o3”.
# usage: DEBUG=1 ./yt-sum.sh  <youtube-url>  [lang]

set -euo pipefail

URL=${1:-}; [[ -z $URL ]] && { echo "usage: $0 <url> [lang]" >&2; exit 1; }
LANG=${2:-en}

YTDLP="./yt-dlp_macos"                 # yt-dlp binary to use
MODEL="o3"
MAX_CHARS=12000

[[ -x $YTDLP ]] || { echo "Cannot execute $YTDLP" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1) download the auto-generated subtitles only
"$YTDLP" --skip-download --write-auto-subs --sub-lang "$LANG" \
         -o "$TMP/%(id)s.%(ext)s" "$URL"

VTT=$(find "$TMP" -name '*.vtt' | head -n1) ||
      { echo "No .vtt subtitles found" >&2; exit 1; }

# 2) convert VTT → plain text (drop timestamps + HTML)
TEXT=$(awk '
        /-->/      {next}
        {gsub(/<[^>]+>/,"")}
        NF
      ' "$VTT")
TEXT=${TEXT:0:$MAX_CHARS}

# 3) wrap in “summarise this” + triple back-ticks
REQUEST_TEXT=$'summarise this in approx 1000 words\n```\n'"$TEXT"$'\n```'

# 4) build JSON for /v1/responses
REQUEST=$(jq -n --arg model "$MODEL" --arg txt "$REQUEST_TEXT" '
          {
            model:     $model,
            reasoning: {effort:"medium"},
            input:     [ {role:"user", content:$txt} ]
          }')

# 5) call the API
RAW=$(curl -sS https://api.openai.com/v1/responses \
       -H "Content-Type: application/json" \
       -H "Authorization: Bearer $OPENAI_API_KEY" \
       -d "$REQUEST")

# Optional debug dump
[[ ${DEBUG:-0} == 1 ]] && { echo "---- RAW JSON ----" >&2; echo "$RAW" | jq . >&2; }

# 6) pull assistant text (handles the layouts seen so far)
SUMMARY=$(echo "$RAW" | jq -r '
          .response[0].content? //
          .output?              //
          .choices[0].message.content? //
          .choices[0].content?  //
          empty')

[[ -z $SUMMARY ]] && { echo "Could not locate summary in API response" >&2; exit 1; }

echo -e "\n—— SUMMARY ——\n$SUMMARY\n"
