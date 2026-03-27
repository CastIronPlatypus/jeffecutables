# smart-cd: `pj` to cd into /data/projects, `pj:name` to cd into /data/projects/name
# Supports aliases: `pj alias <name> <path>`, `pj unalias <name>`, `pj aliases`

_PJ_BASE="/data/projects"
_PJ_CONFIG_DIR="/data/projects/jeffecutables/smart-cd"
_PJ_ALIASES_FILE="$_PJ_CONFIG_DIR/aliases.conf"

# Ensure aliases file exists
[ -f "$_PJ_ALIASES_FILE" ] || touch "$_PJ_ALIASES_FILE"

_pj_resolve() {
  local name="$1"
  # Check aliases first
  local aliased
  aliased=$(grep "^${name}=" "$_PJ_ALIASES_FILE" 2>/dev/null | head -1 | cut -d= -f2-)
  if [ -n "$aliased" ]; then
    echo "$aliased"
  else
    echo "$_PJ_BASE/$name"
  fi
}

pj() {
  case "$1" in
    alias)
      if [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: pj alias <name> <project-or-path>" >&2
        return 1
      fi
      local name="$2"
      local target="$3"
      # If target is not an absolute path, treat it as relative to base
      if [[ "$target" != /* ]]; then
        target="$_PJ_BASE/$target"
      fi
      if [ ! -d "$target" ]; then
        echo "pj: directory '$target' does not exist" >&2
        return 1
      fi
      # Remove existing alias if present, then add
      sed -i "/^${name}=/d" "$_PJ_ALIASES_FILE"
      echo "${name}=${target}" >> "$_PJ_ALIASES_FILE"
      echo "pj: alias '$name' -> $target"
      ;;
    unalias)
      if [ -z "$2" ]; then
        echo "Usage: pj unalias <name>" >&2
        return 1
      fi
      if grep -q "^${2}=" "$_PJ_ALIASES_FILE" 2>/dev/null; then
        sed -i "/^${2}=/d" "$_PJ_ALIASES_FILE"
        echo "pj: removed alias '$2'"
      else
        echo "pj: alias '$2' not found" >&2
        return 1
      fi
      ;;
    aliases)
      if [ -s "$_PJ_ALIASES_FILE" ]; then
        echo "Aliases:"
        while IFS='=' read -r name path; do
          [ -n "$name" ] && printf "  %-15s -> %s\n" "$name" "$path"
        done < "$_PJ_ALIASES_FILE"
      else
        echo "No aliases configured."
      fi
      ;;
    -h|--help|help)
      cat <<'EOF'
pj - quickly cd into projects

Usage:
  pj                     cd to /data/projects
  pj <name>              cd to /data/projects/<name> (or its alias)

Alias management:
  pj alias <name> <path> create an alias (relative paths resolve under /data/projects)
  pj unalias <name>      remove an alias
  pj aliases             list all aliases

Options:
  pj help, pj --help     show this help
EOF
      ;;
    "")
      cd "$_PJ_BASE"
      ;;
    *)
      local resolved
      resolved=$(_pj_resolve "$1")
      if [ -d "$resolved" ]; then
        cd "$resolved"
      else
        echo "pj: project '$1' not found" >&2
        return 1
      fi
      ;;
  esac
}

# Tab completion: project dirs + aliases + subcommands
if [ -n "$ZSH_VERSION" ]; then
  _pj_complete() {
    local -a projects aliases subcmds
    subcmds=(alias unalias aliases help)
    projects=(${$(command ls -1 "$_PJ_BASE" 2>/dev/null)})
    if [ -s "$_PJ_ALIASES_FILE" ]; then
      aliases=(${$(cut -d= -f1 "$_PJ_ALIASES_FILE" 2>/dev/null)})
    fi
    _describe 'command' subcmds -- projects -- aliases
  }
  compdef _pj_complete pj
elif [ -n "$BASH_VERSION" ]; then
  _pj_complete_bash() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local words="alias unalias aliases help"
    words+=" $(command ls -1 "$_PJ_BASE" 2>/dev/null)"
    if [ -s "$_PJ_ALIASES_FILE" ]; then
      words+=" $(cut -d= -f1 "$_PJ_ALIASES_FILE" 2>/dev/null)"
    fi
    COMPREPLY=($(compgen -W "$words" -- "$cur"))
  }
  complete -F _pj_complete_bash pj
fi
