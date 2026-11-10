---
name: agnes-video
description: 用 agnes CLI 调用 Agnes AI 生成视频（文生视频、图生视频、多图关键帧过渡），并把结果下载到工作区交付。当用户要求做视频、视频片段、动图、动画、把图片变成视频时使用。
version: 1.0.0
---

# Agnes 生成视频

`agnes` CLI 调用 Agnes 视频模型。当前只有 `agnes-video-v2.0` 一个模型，也是默认值。

## 前置检查

```bash
agnes key status
```

- `"status": "missing"` 说明没配 Key（和图片共用同一个 Key）。
- 不要编造 Key，也不要把 Key 写进项目文件或回复正文。

## 文生视频

```bash
agnes video generate --prompt "描述" --num-frames 121 --frame-rate 24
```

- 成功时 **stdout 只有视频 URL**，任务 ID / 进度 / 错误走 stderr。
- 时长 ≈ `num-frames / frame-rate`：121 帧 @24fps ≈ 5 秒，25 帧 ≈ 1 秒。
- `--num-frames` 上限 441，且必须是 `8n + 1`（如 25、121、241、441）。
- `--frame-rate` 范围 1–60，默认 24。
- 分辨率默认 1152×768，可用 `--width` / `--height` 覆盖。
- 默认超时 600 秒，长视频记得调大 `--timeout`。

## 图生视频与关键帧过渡

```bash
# 单图动起来
agnes video generate --prompt "镜头缓慢推进" --image ./ref.png

# 两图之间的过渡（首尾帧）
agnes video generate --prompt "从白天平滑过渡到夜晚" \
  --image ./start.png --image ./end.png --mode keyframes
```

`--image` 可重复，支持本地路径、公网 URL、Data URI；本地文件会自动转 Data URI。

## 下载与交付（必做）

URL 是临时链接，必须落到工作区：

```bash
mkdir -p output
curl -sSL "<URL>" -o "output/agnes-$(date +%Y%m%d-%H%M%S).mp4"
file output/*.mp4 && ls -l output/*.mp4
```

交付时给出：文件路径、分辨率、时长（`num-frames / frame-rate`）、模型名。确认文件非空再回复。

## 查询任务

```bash
agnes video status <task_id>
```

适用于 generate 超时或中断后继续追结果。

## 常见问题

- `HTTP 500` + `get_channel_failed` / `Model agnes-video-v2.0 is temporarily unavailable`：**上游模型通道不可用**，既不是 Key 失效也不是参数错误。隔一段时间重试即可，不要改参数硬试、也不要重复刷额度。
- `type: "validation"`：参数不合法（最常见是 `num-frames` 不满足 `8n+1` 或超过 441），按 `hint` 修正。
- `type: "auth"`：Key 未配置或失效，先 `agnes key status`。
- 视频生成比图片慢得多，Bash 超时至少给 600000 ms；一次只跑一个视频任务。
