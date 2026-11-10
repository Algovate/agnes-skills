---
name: agnes-image
description: 用 agnes-img 调用 Agnes AI 生成或编辑图片（文生图、图生图、多图合成），默认走最新的 2.5 模型并在失败时自动降级 2.1，结果下载到工作区展示。当用户要求画图、生图、生成配图/海报/插画/素材，或改图、换风格、合成参考图时使用。
version: 1.2.0
---

# Agnes 生图

`agnes-img` 是 `agnes image generate` 的包装：同样的参数，额外支持 2.5 模型和自动降级。
当前 2.5（`agnes-image-2.5-flash`）是默认，2.1（`agnes-image-2.1-flash`）作为降级与兼容档。

## 前置检查

```bash
agnes key status
```

- `"status": "missing"` 表示未配置 Key。让用户打开 https://platform.agnes-ai.com 生成 API Key，然后执行 `agnes key set <KEY>`（写入本地配置）或设置环境变量 `AGNES_API_KEY`。
- 不要编造 Key，也不要把 Key 写进项目文件或回复正文。

## 模型选择

| 需求 | 用法 |
|---|---|
| 默认（正式交付） | 什么都不传 → `agnes-image-2.5-flash` |
| 指定 2.1 | `--model 2.1` |
| 改默认档 | 环境变量 `AGNES_IMAGE_MODEL=2.1` |
| 关掉自动降级 | `--no-fallback`（或 `AGNES_IMAGE_FALLBACK=0`） |

- 优先级：`--model` > `AGNES_IMAGE_MODEL` > 默认 2.5。
- 2.5 返回 5xx 时会**自动用 2.1 重试一次**，stderr 会打印 `role=fallback`；回复里应说明实际用的模型。
- stderr 总会打印 `generated with <model>`，据此在回复中标注模型。

## 文生图

```bash
agnes-img --prompt "描述" --size 2K
```

- 成功时 **stdout 只有图片 URL**，模型名/任务 ID/降级信息/错误走 stderr。
- `--size` 支持档位 `1K` / `2K` / `3K` / `4K`，也兼容 `1024x768` 这类精确值（默认 `1024x768`）。
- 档位默认 1:1；需要 16:9、9:16 等比例时传对应的原生尺寸，例如 16:9 用 `1312x736`（1K）或 `2624x1472`（2K），9:16 用 `736x1312`。

## 图生图与多图合成

```bash
agnes-img --prompt "改成赛博朋克夜景" --image ./ref.png
agnes-img --prompt "融合这两张参考图做海报" --image ./a.png --image ./b.png
```

- `--image` 可重复，支持本地路径、公网 URL 或 Data URI；本地文件会自动转成 Data URI。
- 改图时提示词写"保留什么、改变什么"效果更稳。

## 保存与展示（必做）

URL 是临时链接，必须下载到工作区：

```bash
mkdir -p output output/drafts
curl -sSL "<URL>" -o "output/agnes-$(date +%Y%m%d-%H%M%S).png"
ls -l output/*.png
```

- 确认文件非空（`file` / 大小 > 0）后再交付。
- 用 `read_image` 预览成图；回复里用 `![说明](output/xxx.png)` 展示，或按需 `present`。

## 输出目录约定（必须遵守）

```
output/                       交付图，永久保留
  <subject>.png               主题主图，如 eagle-hare.png
  <subject>-<variant>.png     同主题的另一种交付风格，如 eagle-hare-ink.png
output/drafts/                中间稿 / 被取代的版本，7 天后可清
  <subject>-<variant>-<YYYYMMDD-HHMM>.png
```

规则：

1. **交付图**直接落到 `output/<主题>.png`；命名用小写连字符、英文语义化，不要 `-v2`、`-final`、`-副本` 这类临时后缀。
2. **被新版本取代的旧图**，在新图确认交付后 `mv` 到 `output/drafts/<主题>-<时间戳>.png`，不要留在 `output/` 里混淆。
3. **没打算交付的试验稿**（试构图、试参数）直接写 `output/drafts/`。
4. 清理一律用 `agnes-gc`，不要手动 `rm` 整个 output：

```bash
agnes-gc              # 预览：drafts 中超过 7 天的
agnes-gc --apply      # 执行
agnes-gc --all        # 预览：清空 drafts
```

`agnes-gc` 只允许作用于名为 `drafts` 的目录，`output/` 里的交付图永远不会被它删除。

## 常见问题

- `{"ok":false,"error":{"type":"auth",...}}`：Key 未配置或失效，先 `agnes key status`。
- `type: "validation"`：参数不合法（例如不支持的 model、缺少 `--prompt`），按 `hint` 修正，不要盲目重试。
- 2.5 报 5xx：会自动降级到 2.1；若 stderr 出现 `role=fallback`，说明这次是降级产物，交付时要说明。
- 生成通常 10–60 秒，Bash 超时至少设 180000 ms。
- 一次只跑一个生成任务，避免并发刷额度。

## 兼容说明

老的 `agnes image generate` 仍然可用，但 `--model` 只接受 `agnes-image-2.1-flash` / `agnes-image-2.0-flash`，**不支持 2.5**。需要 2.5 或自动降级时一律用 `agnes-img`。
