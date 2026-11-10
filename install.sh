#!/usr/bin/env bash
# 安装 agnes-skills：把技能软链到 agent 的技能目录，把工具软链到 PATH。
#
#   ./install.sh              # 软链安装（默认）
#   AGNES_BIN_HOME=~/.bin ./install.sh
#   DSH_AGENTS_HOME=~/.agents ./install.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_HOME="${DSH_AGENTS_HOME:-$HOME/.agents}/skills"
BIN_HOME="${AGNES_BIN_HOME:-$HOME/.local/bin}"

mkdir -p "$SKILL_HOME" "$BIN_HOME"

for dir in "$ROOT"/skills/*/; do
  name="$(basename "$dir")"
  ln -sfn "$dir" "$SKILL_HOME/$name"
  echo "skill  $SKILL_HOME/$name"
done

for file in "$ROOT"/tools/*; do
  chmod +x "$file"
  ln -sfn "$file" "$BIN_HOME/$(basename "$file")"
  echo "tool   $BIN_HOME/$(basename "$file")"
done

# launchd / systemd 服务常常拿不到 ~/.local/bin，额外链一份到 homebrew 目录
if [[ -d /opt/homebrew/bin && -w /opt/homebrew/bin ]]; then
  for file in "$ROOT"/tools/*; do
    ln -sfn "$file" "/opt/homebrew/bin/$(basename "$file")"
    echo "tool   /opt/homebrew/bin/$(basename "$file")"
  done
fi

echo
echo "完成。下一步："
echo "  1) 配置 key：agnes key set <KEY>"
echo "  2) 自检：agnes-img --dry-run --prompt test"
