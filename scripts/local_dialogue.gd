extends Node

signal availability_changed

const MODEL_NAME := "qwen3.5:4b"
const MIN_RAM_BYTES := 8 * 1024 * 1024 * 1024
const OLLAMA_URL := "http://127.0.0.1:11434"
const BUNDLED_URL := "http://127.0.0.1:18867"

var available := false
var checking := false
var reason := "正在检查本地对话环境……"
var backend := ""
var server_pid := -1


func _ready() -> void:
	call_deferred("check_availability")


func _exit_tree() -> void:
	if server_pid > 0 and OS.is_process_running(server_pid):
		OS.kill(server_pid)


func check_availability() -> void:
	if checking:
		return
	checking = true
	available = false
	backend = ""
	var physical := int(OS.get_memory_info().get("physical", -1))
	if physical > 0 and physical < MIN_RAM_BYTES:
		_finish_check("可用内存不足 8 GB，无法可靠运行本地 4B 模型。")
		return
	var game_dir := OS.get_executable_path().get_base_dir()
	var helper := game_dir.path_join("ai/runtime/llama-server.exe")
	if OS.get_name() == "macOS":
		helper = game_dir.path_join("ai/llama-server")
	var model := game_dir.path_join("ai/qwen3.5-4b-q4_k_m.gguf")
	if FileAccess.file_exists(helper) and FileAccess.file_exists(model):
		server_pid = OS.create_process(helper, ["--model", model, "--host", "127.0.0.1", "--port", "18867", "--ctx-size", "4096", "--parallel", "1", "--n-gpu-layers", "auto", "--no-ui"])
		if server_pid > 0:
			for attempt in 30:
				var health := await _json_request(BUNDLED_URL + "/health", {}, HTTPClient.METHOD_GET, 2.0)
				if health.get("ok", false) and health.get("data", {}).get("status", "") == "ok":
					backend = "llama"
					available = true
					_finish_check("")
					return
				await get_tree().create_timer(0.5).timeout
		if server_pid > 0 and OS.is_process_running(server_pid):
			OS.kill(server_pid)
		server_pid = -1
		_finish_check("随游戏提供的本地模型启动失败。")
		return
	var listing := await _json_request(OLLAMA_URL + "/api/tags", {}, HTTPClient.METHOD_GET, 3.0)
	if not listing.get("ok", false):
		_finish_check("未连接到本机 Ollama，且游戏目录内没有推理程序和 4B 模型。")
		return
	var found := false
	for item in listing.get("data", {}).get("models", []):
		if item is Dictionary and str(item.get("name", "")) == MODEL_NAME:
			found = true
			break
	if not found:
		_finish_check("未找到 %s；不会自动使用更大的模型。" % MODEL_NAME)
		return
	var warmup := await _json_request(OLLAMA_URL + "/api/generate", {
		"model": MODEL_NAME, "prompt": "你好", "stream": false, "think": false,
		"options": {"num_ctx": 4096, "num_predict": 1}, "keep_alive": "5m"
	}, HTTPClient.METHOD_POST, 75.0)
	if not warmup.get("ok", false) or warmup.get("data", {}).has("error"):
		_finish_check("本地 4B 模型加载失败，可能是内存或显存不足。")
		return
	backend = "ollama"
	available = true
	_finish_check("")


func _finish_check(failure: String) -> void:
	reason = failure
	checking = false
	availability_changed.emit()


func reply(messages: Array) -> Dictionary:
	if not available:
		return {"ok": false, "error": reason}
	var payload := {"model": MODEL_NAME, "messages": messages, "stream": false, "think": false,
		"options": {"num_ctx": 4096, "num_predict": 240, "temperature": 0.72}}
	var url := OLLAMA_URL + "/api/chat"
	if backend == "llama":
		url = BUNDLED_URL + "/v1/chat/completions"
		payload = {"messages": messages, "stream": false, "max_tokens": 240, "temperature": 0.72,
			"chat_template_kwargs": {"enable_thinking": false}}
	var response := await _json_request(url, payload, HTTPClient.METHOD_POST, 80.0)
	if not response.get("ok", false):
		return {"ok": false, "error": "本地模型未能回复，请稍后重试。"}
	var data: Dictionary = response["data"]
	if data.has("error"):
		return {"ok": false, "error": str(data["error"])}
	var content := ""
	if backend == "ollama":
		content = str(data.get("message", {}).get("content", ""))
	else:
		var choices: Array = data.get("choices", [])
		if not choices.is_empty():
			content = str(choices[0].get("message", {}).get("content", ""))
	content = content.strip_edges()
	if content.is_empty():
		return {"ok": false, "error": "本地模型返回了空消息，请再试一次。"}
	return {"ok": true, "text": content}


func _json_request(url: String, payload: Dictionary, method: HTTPClient.Method, timeout: float) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = timeout
	add_child(request)
	var body := JSON.stringify(payload) if method == HTTPClient.METHOD_POST else ""
	var started := request.request(url, ["Content-Type: application/json"], method, body)
	if started != OK:
		request.queue_free()
		return {"ok": false}
	var completed: Array = await request.request_completed
	request.queue_free()
	if completed[0] != HTTPRequest.RESULT_SUCCESS or int(completed[1]) != 200:
		return {"ok": false}
	var parsed: Variant = JSON.parse_string(completed[3].get_string_from_utf8())
	if not parsed is Dictionary:
		return {"ok": false}
	return {"ok": true, "data": parsed}
