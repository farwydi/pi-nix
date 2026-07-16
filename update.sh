#!/usr/bin/env bash
# Перегенерирует sources.json и npm-shrinkwrap.json под последнюю версию pi.
# Пин версии аргументом: ./update.sh 0.80.9
set -euo pipefail
cd "$(dirname "$0")"

pkg="@earendil-works/pi-coding-agent"
ver="${1:-$(curl -fsSL "https://registry.npmjs.org/$pkg/latest" | jq -r .version)}"
[ -n "$ver" ] && [ "$ver" != "null" ] || { echo "could not determine latest version" >&2; exit 1; }

cur=$(jq -r .version sources.json 2>/dev/null || echo "")
if [ "$ver" = "$cur" ]; then
  echo "already at $ver"
  exit 0
fi

meta=$(curl -fsSL "https://registry.npmjs.org/$pkg/$ver")
srcHash=$(jq -re .dist.integrity <<<"$meta")
url=$(jq -re .dist.tarball <<<"$meta")

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$url" | tar xz -C "$tmp"
sw="$tmp/package/npm-shrinkwrap.json"

# сиблинг-пакеты pi публикуются в shrinkwrap без integrity — дозаписываем из registry
while IFS=$'\t' read -r key pver; do
  name="${key##*node_modules/}"
  integrity=$(curl -fsSL "https://registry.npmjs.org/$name/$pver" | jq -re .dist.integrity)
  jq --arg k "$key" --arg i "$integrity" '.packages[$k].integrity = $i' "$sw" > "$sw.new"
  mv "$sw.new" "$sw"
done < <(jq -r '.packages | to_entries[]
  | select(.key != "" and (.value.integrity // "") == "" and (.value.resolved // "" | startswith("https://registry.npmjs.org/")))
  | "\(.key)\t\(.value.version)"' "$sw")

npmDepsHash=$(nix-build '<nixpkgs>' -A prefetch-npm-deps --no-out-link >/dev/null 2>&1;
  "$(nix-build '<nixpkgs>' -A prefetch-npm-deps --no-out-link)/bin/prefetch-npm-deps" "$sw")

cp "$sw" npm-shrinkwrap.json
jq -n --arg v "$ver" --arg s "$srcHash" --arg n "$npmDepsHash" \
  '{version: $v, srcHash: $s, npmDepsHash: $n}' > sources.json
echo "updated to $ver"
