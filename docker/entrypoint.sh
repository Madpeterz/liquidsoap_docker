#!/bin/sh
set -eu

escape_liq() {
  printf '%s' "$1" | sed 's/[\\"]/\\&/g'
}

require_int() {
  value="$1"
  name="$2"
  case "$value" in
    ''|*[!0-9]*)
      echo "$name must be an integer, got: $value" >&2
      exit 1
      ;;
  esac
}

require_bool() {
  value="$1"
  name="$2"
  case "$value" in
    true|false) ;;
    *)
      echo "$name must be true or false, got: $value" >&2
      exit 1
      ;;
  esac
}

: "${LIQ_SOURCE_MODE:=single}"
: "${LIQ_SOURCE_URI:=/data/stream.mp3}"
: "${LIQ_NEXT_SONG_URL:=}"
: "${LIQ_OUTPUT_SERVER:=shoutcast2}"
: "${ICECAST_HOST:=icecast}"
: "${ICECAST_PORT:=8000}"
: "${ICECAST_USER:=source}"
: "${ICECAST_PASSWORD:=hackme}"
: "${ICECAST_MOUNT:=/stream.mp3}"
: "${ICECAST_PROTOCOL:=}"
: "${ICECAST_NAME:=Liquidsoap}"
: "${ICECAST_DESCRIPTION:=Liquidsoap stream}"
: "${ICECAST_GENRE:=Radio}"
: "${ICECAST_URL:=http://localhost}"
: "${ICECAST_PUBLIC:=false}"
: "${ICECAST_BITRATE:=128}"

require_int "$ICECAST_PORT" ICECAST_PORT
require_int "$ICECAST_BITRATE" ICECAST_BITRATE
require_bool "$ICECAST_PUBLIC" ICECAST_PUBLIC

if [ "$LIQ_NEXT_SONG_URL" = "random" ]; then
  random_playlist=/tmp/liquidsoap-random-playlist.m3u

  find /data -type f \( -iname '*.mp3' \) | sort > "$random_playlist"

  if [ ! -s "$random_playlist" ]; then
    echo "LIQ_NEXT_SONG_URL=random requires at least one .mp3 file in /data (including subfolders)" >&2
    exit 1
  fi

  LIQ_SOURCE_MODE=playlist
  LIQ_SOURCE_URI="$random_playlist"
  LIQ_SOURCE_RANDOMIZE=true
  echo "Configured random playlist from /data: $random_playlist" >&2
elif [ -n "$LIQ_NEXT_SONG_URL" ]; then
  next_song_path=$(printf '%s' "$LIQ_NEXT_SONG_URL" | sed -E 's|^[A-Za-z][A-Za-z0-9+.-]*://[^/]*||' | sed 's/[?#].*$//')
  case "$next_song_path" in
    ''|'/')
      echo "LIQ_NEXT_SONG_URL must include a path to a file, got: $LIQ_NEXT_SONG_URL" >&2
      exit 1
      ;;
  esac

  next_song_file=${next_song_path##*/}
  next_song_folder=${next_song_path%/*}
  if [ -z "$next_song_file" ]; then
    echo "LIQ_NEXT_SONG_URL must include a filename, got: $LIQ_NEXT_SONG_URL" >&2
    exit 1
  fi

  if [ -z "$next_song_folder" ] || [ "$next_song_folder" = "$next_song_path" ]; then
    next_song_folder="/"
  fi

  if [ "$next_song_folder" = "/" ]; then
    LIQ_SOURCE_URI="/${next_song_file}"
  else
    LIQ_SOURCE_URI="${next_song_folder}/${next_song_file}"
  fi

  echo "Derived LIQ_SOURCE_URI from LIQ_NEXT_SONG_URL: $LIQ_SOURCE_URI" >&2
fi

source_uri=$(escape_liq "$LIQ_SOURCE_URI")
icecast_host=$(escape_liq "$ICECAST_HOST")
icecast_user=$(escape_liq "$ICECAST_USER")
icecast_password=$(escape_liq "$ICECAST_PASSWORD")
icecast_mount=$(escape_liq "$ICECAST_MOUNT")
icecast_name=$(escape_liq "$ICECAST_NAME")
icecast_description=$(escape_liq "$ICECAST_DESCRIPTION")
icecast_genre=$(escape_liq "$ICECAST_GENRE")
icecast_url=$(escape_liq "$ICECAST_URL")

case "$LIQ_OUTPUT_SERVER" in
  shoutcast2|icecast)
    ;;
  *)
    echo "LIQ_OUTPUT_SERVER must be shoutcast2 or icecast, got: $LIQ_OUTPUT_SERVER" >&2
    exit 1
    ;;
esac

case "$LIQ_SOURCE_MODE" in
  single)
    source_expr="mksafe(single(\"$source_uri\"))"
    ;;
  playlist)
    if [ "${LIQ_SOURCE_RANDOMIZE:-false}" = "true" ]; then
      source_expr="mksafe(playlist(mode=\"randomize\", \"$source_uri\"))"
    else
      source_expr="mksafe(playlist(\"$source_uri\"))"
    fi
    ;;
  *)
    echo "LIQ_SOURCE_MODE must be single or playlist, got: $LIQ_SOURCE_MODE" >&2
    exit 1
    ;;
esac

if [ "$LIQ_OUTPUT_SERVER" = "shoutcast2" ]; then
  cat > /tmp/stream.liq <<EOF
settings.log.stdout := true

radio = ${source_expr}

output.shoutcast(
  %mp3(
    bitrate=${ICECAST_BITRATE},
    stereo=true
  ),
  host="${icecast_host}",
  port=${ICECAST_PORT},
  password="${icecast_password}",
  radio
)
EOF
else
  cat > /tmp/stream.liq <<EOF
settings.log.stdout := true

radio = ${source_expr}

output.icecast(
  %mp3(
    bitrate=${ICECAST_BITRATE},
    stereo=true
  ),
  host="${icecast_host}",
  port=${ICECAST_PORT},
  user="${icecast_user}",
  password="${icecast_password}",
  mount="${icecast_mount}",
  name="${icecast_name}",
  description="${icecast_description}",
  genre="${icecast_genre}",
  url="${icecast_url}",
  public=${ICECAST_PUBLIC},
  radio
)
EOF
fi

exec liquidsoap /tmp/stream.liq