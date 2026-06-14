# Liquidsoap Docker

This workspace includes:

- A fetched Unix package asset at `vendor/liquidsoap_2.4.4-ubuntu-noble-ocaml4.14.2-1_amd64.deb`
- A Dockerfile that downloads the matching Liquidsoap package during build
- An entrypoint that generates a Liquidsoap script from environment variables

## Build

```sh
docker build -t liquidsoap-env .
```

The image build uses the vendored Liquidsoap package at `vendor/liquidsoap_2.4.4-ubuntu-noble-ocaml4.14.2-1_amd64.deb`, so it does not download Liquidsoap during the Docker build.

## Run

```sh
docker run --rm \
  -e LIQ_SOURCE_MODE=single \
  -e LIQ_SOURCE_URI=/data/track.mp3 \
  -e LIQ_NEXT_SONG_URL=https://media.example.com/music/set1/track.mp3 \
  -e LIQ_OUTPUT_SERVER=shoutcast2 \
  -e ICECAST_HOST=your.shoutcast.host \
  -e ICECAST_PORT=8000 \
  -e ICECAST_USER=source \
  -e ICECAST_PASSWORD=your_source_password \
  -e ICECAST_MOUNT=/stream.mp3 \
  -e ICECAST_PROTOCOL=icy \
  -e ICECAST_NAME="My Station" \
  -e ICECAST_DESCRIPTION="Containerized Liquidsoap" \
  -e ICECAST_GENRE=Radio \
  -e ICECAST_URL=http://example.com \
  -e ICECAST_PUBLIC=false \
  -e ICECAST_BITRATE=128 \
  -v /path/to/media:/data \
  liquidsoap-env
```

## Environment

- `LIQ_SOURCE_MODE`: `single` or `playlist`
- `LIQ_SOURCE_URI`: file path or playlist path inside the container
- `LIQ_NEXT_SONG_URL`: optional URL for the next song. When set, the script extracts folder and file name from the URL path and derives `LIQ_SOURCE_URI` from it (query string and fragment are ignored).
- `LIQ_NEXT_SONG_URL=random`: build a playlist from all `.mp3` files in `/data` (including subfolders) and play them in random order
- `LIQ_OUTPUT_SERVER`: `shoutcast2` or `icecast` (defaults to `shoutcast2`)
- `ICECAST_HOST`: streaming server hostname
- `ICECAST_PORT`: streaming server port
- `ICECAST_USER`: source username (typically `source` for Shoutcast2)
- `ICECAST_PASSWORD`: Source password
- `ICECAST_MOUNT`: Mount path, for example `/stream.mp3`
- `ICECAST_PROTOCOL`: currently ignored by this image because Liquidsoap 2.4.4 `output.icecast` in the bundled package does not accept a `protocol` parameter.
- `ICECAST_NAME`: Stream display name
- `ICECAST_DESCRIPTION`: Stream description
- `ICECAST_GENRE`: Stream genre
- `ICECAST_URL`: Public station URL
- `ICECAST_PUBLIC`: `true` or `false`
- `ICECAST_BITRATE`: MP3 bitrate in kbps

## GitHub Actions: Auto Build and Push

Workflow file:

- `.github/workflows/docker-publish.yml`

Triggers:

- Push to `main`
- Version tags like `v1.0.0`
- Manual run (`workflow_dispatch`)

### Required Repository Secrets

Set these in GitHub: Settings -> Secrets and variables -> Actions:

- `DOCKER_REGISTRY` (example: `docker.io`)
- `DOCKER_IMAGE_NAME` (example: `youruser/shoutcast2`)
- `DOCKER_USERNAME`
- `DOCKER_TOKEN`

The workflow publishes tags for branch, git tag, commit SHA, and `latest` on the default branch.