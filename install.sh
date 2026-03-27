#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SNIPPET='# jeffecutables: add all subdirectories to PATH
for dir in '"$SCRIPT_DIR"'/*/; do
  [[ ":$PATH:" != *":$dir:"* ]] && export PATH="$dir:$PATH"
done'

# Detect shell RC file
if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
  RC="$HOME/.zshrc"
else
  RC="$HOME/.bashrc"
fi

if grep -qF "jeffecutables" "$RC" 2>/dev/null; then
  echo "Already installed in $RC"
  exit 0
fi

printf '\n%s\n' "$SNIPPET" >> "$RC"
echo "Added jeffecutables PATH setup to $RC"
echo "Run 'source $RC' or open a new terminal to activate."
