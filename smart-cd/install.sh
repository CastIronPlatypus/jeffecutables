#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LINE="source \"$SCRIPT_DIR/pj.sh\""

installed=0

for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  if grep -qF "$SOURCE_LINE" "$rc" 2>/dev/null; then
    echo "Already in $rc, skipping."
  else
    printf '\n# smart-cd\n%s\n' "$SOURCE_LINE" >> "$rc"
    echo "Added to $rc"
  fi
  installed=1
done

if [ "$installed" -eq 0 ]; then
  echo "No ~/.zshrc or ~/.bashrc found. Creating ~/.bashrc." >&2
  printf '# smart-cd\n%s\n' "$SOURCE_LINE" > "$HOME/.bashrc"
  echo "Added to ~/.bashrc"
fi

echo "Restart your shell or run: source $SCRIPT_DIR/pj.sh"
