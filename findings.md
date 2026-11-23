# 调查记录

- 项目已有 `social.tscn` 书本式 UI，`social.gd` 原有一次性“发消息”加好感度功能。
- 当前只有已结识的月侧阳奈里出现在通讯录；角色定义位于 `social_characters.gd`。
- `D:\Ollama\ollama.exe` 存在，但沙箱内 `ollama list` 连接 127.0.0.1:11434 被拒；模型名尚待核实。
- `D:\OllamaModels\manifests\registry.ollama.ai\library\qwen3.5\latest` 当前实际上指向 9.7B Q4_K_M（6.59 GB 权重）；未发现 4B manifest。不能默认使用 latest。
- Godot 存在于 `.ignore/Godot_v4.8-dev3_win64.exe/`。社交有手机书本界面及现场交流共用 `social.gd`；手机中仅在公园初遇后解锁。
- 可用 `OS.get_memory_info().physical` 做低内存拦截；Godot 不提供可靠的跨平台可用 VRAM 值，因此还需实际模型加载/请求结果判断。
- 本机 Ollama 服务的 `show --modelfile` 指向 Linux `/usr/share/ollama/...`，Windows `OLLAMA_MODELS=D:\OllamaModels` 并非该服务实际存储位置；正式 Windows 导出需另备独立 GGUF。
- 评委版 Windows 候选：llama.cpp b12633 Vulkan 预编译包；`llama-server.exe` 与 DLL 同目录在 `ai/runtime/`，模型在 `ai/`。
- 工作树包含大量其他暂存改动，不回退它们。
