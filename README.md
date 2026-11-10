# agnes-skills

给 AI agent 用的 [Agnes](https://platform.agnes-ai.com) 图像 / 视频生成技能包，外加两个补齐官方 CLI 短板的命令行工具。

面向 DeepSeek Harness（DSH）之类的 agent 框架：技能以 `SKILL.md` 形式提供，工具是普通可执行脚本。

## 包含什么

| 内容 | 说明 |
|---|---|
| `skills/agnes-image` | 文生图 / 图生图 / 多图合成。默认走 `agnes-image-2.5-flash`，失败自动降级 2.1 |
| `skills/agnes-video` | 文生视频 / 图生视频 / 关键帧过渡（`agnes-video-v2.0`） |
| `tools/agnes-img` | 官方 CLI 只支持 2.0/2.1，这个壳补上 2.5 与自动降级 |
| `tools/agnes-gc` | 清理中间稿目录，带目录名护栏，绝不碰交付图 |

## 为什么需要 `agnes-img`

官方 `@agnes-ai/agnes-cli` 的 `image generate --model` 白名单只到 `agnes-image-2.0-flash` / `agnes-image-2.1-flash`，而 API 已经有 `agnes-image-2.5-flash`。所以：

```bash
agnes image generate --model agnes-image-2.5-flash   # ❌ 被 CLI 拦下
agnes-img --prompt "..."                             # ✅ 默认就是 2.5
```

模型选择优先级：

```
--model 2.5|2.1  >  $AGNES_IMAGE_MODEL  >  默认 2.5
                              ↓ 2.5 返回 5xx
                     自动用 2.1 重试一次
```

## 安装

```bash
git clone git@github.com:Algovate/agnes-skills.git
cd agnes-skills
./install.sh
```

`install.sh` 做的事：

- 把 `skills/*` 软链到 `${DSH_AGENTS_HOME:-~/.agents}/skills/`
- 把 `tools/*` 软链到 `${AGNES_BIN_HOME:-~/.local/bin}`
- 若存在 `/opt/homebrew/bin`，额外把工具链进去（launchd 服务的 PATH 通常不含 `~/.local/bin`）

软链安装，所以 `git pull` 后技能与工具立即生效。

### 依赖

- `agnes` CLI：`npm install -g --prefix "$HOME/.local" @agnes-ai/agnes-cli`
- Python 3（`agnes-img` 只用标准库）
- API key：`agnes key set <KEY>`（写到钥匙串或 `~/.config/agnes/config.yml`）

`agnes-img` 按 **环境变量 → `~/.config/agnes/config.yml` → macOS 钥匙串（service `agnes-cli`）** 的顺序找 key，兼容有/无钥匙串两种环境。

## 用法

```bash
# 文生图（默认 2.5）
agnes-img --prompt "a red apple on white, product photo" --size 2K

# 指定旧模型
agnes-img --prompt "..." --model 2.1

# 关掉自动降级
agnes-img --prompt "..." --no-fallback

# 改图 / 多图合成
agnes-img --prompt "改成水墨风格，保留构图" --image ./ref.png
agnes-img --prompt "融合成海报" --image ./a.png --image ./b.png

# 只看请求体，不联网
agnes-img --prompt "..." --dry-run

# 视频
agnes video generate --prompt "..." --num-frames 121 --frame-rate 24
```

`stdout` 只输出结果 URL（图片每行一个），模型名、任务 ID、降级告警全部走 `stderr`，方便 agent 解析。

## 输出目录约定

```
output/                       交付图，永久保留
  <subject>.png
  <subject>-<variant>.png
output/drafts/                中间稿、被取代的版本，7 天后可清
  <subject>-<variant>-<YYYYMMDD-HHMM>.png
```

清理：

```bash
agnes-gc              # 预览 7 天前的
agnes-gc --apply      # 执行
agnes-gc --all        # 预览清空
```

`agnes-gc` 只允许作用于 basename 为 `drafts` 的目录，`output/` 不会被误删。

## 验证

`tests/stub-agnes-api.py` 是一个假 API：对 2.5 返回 500、对其他模型返回成功，用来验证降级链路。

```bash
python3 tests/stub-agnes-api.py &          # 监听 127.0.0.1:18011
agnes-img --base-url http://127.0.0.1:18011 --prompt "x"
# 期望 stderr: 2.5 failed → role=fallback → 2.1 成功；stdout: 假 URL
agnes-img --base-url http://127.0.0.1:18011 --prompt "x" --no-fallback
# 期望 exit 1，不重试
```

## 注意

- 仓库里**不含任何 key**；key 只存在本机钥匙串或配置文件里
- 视频模型由上游单独供能，可能整段不可用（`HTTP 500 get_channel_failed` 属平台侧问题，改参数无用）
- 视频通常按条计费，图片是否有额度限制取决于你的账户

## License

MIT
