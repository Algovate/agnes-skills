#!/usr/bin/env bash
# 安装 agnes-skills：把技能软链到 agent 的技能目录，把工具软链到 PATH。
#
#   ./install.sh
#   AGNES_BIN_HOME=~/.bin ./install.sh
#   DSH_AGENTS_HOME=~/.agents ./install.sh
#   AGNES_HOMEBREW_LINK=0 ./install.sh     # 不往 /opt/homebrew/bin 建链
#
# 已存在的真实目录/文件会先备份为 *.bak-<时间戳> 再建链，不会被覆盖丢失。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_HOME="${DSH_AGENTS_HOME:-$HOME/.agents}/skills"
BIN_HOME="${AGNES_BIN_HOME:-$HOME/.local/bin}"
STAMP="$(date +%Y%m%d-%H%M%S)"

link() {  # link <target> <linkpath>
  local target="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    mv "$dest" "$dest.bak-$STAMP"
    echo "backup $dest.bak-$STAMP"
  fi
  ln -sfn "$target" "$dest"
  echo "link   $dest -> $target"
}

mkdir -p "$SKILL_HOME" "$BIN_HOME"

for dir in "$ROOT"/skills/*/; do
  link "$dir" "$SKILL_HOME/$(basename "$dir")"
done

for file in "$ROOT"/tools/*; do
  [[ -f "$file" ]] || continue
  chmod 755 "$file"
  link "$file" "$BIN_HOME/$(basename "$file")"
done

if [[ "${AGNES_HOMEBREW_LINK:-1}" != "0" && -d /opt/homebrew/bin && -w /opt/homebrew/bin ]]; then
  for file in "$ROOT"/tools/*; do
    [[ -f "$file" ]] || continue
    link "$file" "/opt/homebrew/bin/$(basename "$file")"
  done
fi

echo
echo "完成。下一步："
echo "  1) 配置 key：agnes key set <KEY>"
echo "  2) 自检：agnes-img --dry-run --prompt test"
