extends Control

var b64 = false
var b32 = false
var barm = false

func _ready() -> void:
	Global.is_extract.connect(reflash_button)
	if Global.get_system_architecture() != "unknown":
		$PanelContainer/Control/VBoxContainer/System.text = "你的系统架构："+Global.get_system_architecture()
	if Global.currently_python_interpreter != null:
		$PanelContainer/Control/VBoxContainer/Content.text = "选择你的代码解释器架构：\n（当前："+Global.currently_python_interpreter+"）"
	if Global.is_folder_exist_and_not_empty("C:/okay_language_engine"):
		if Global.is_folder_exist_and_not_empty("C:/okay_language_engine/python-amd64"):
			$"PanelContainer/Control/VBoxContainer/64".text = "AMD-64bit（已安装）"
			b64 = true
		if Global.is_folder_exist_and_not_empty("C:/okay_language_engine/python-arm64"):
			$"PanelContainer/Control/VBoxContainer/arm".text = "ARM64（已安装）"
			barm = true
		if Global.is_folder_exist_and_not_empty("C:/okay_language_engine/python-win32"):
			$"PanelContainer/Control/VBoxContainer/32".text = "WIN-32bit（已安装）"
			b32 = true
	else:
		pass

func _on_back_pressed() -> void:
	hide()

func reflash_button():
	if Global.is_folder_exist_and_not_empty("C:/okay_language_engine"):
		if Global.is_folder_exist_and_not_empty("C:/okay_language_engine/python-amd64"):
			$"PanelContainer/Control/VBoxContainer/64".text = "AMD-64bit（已安装）"
			b64 = true
		if Global.is_folder_exist_and_not_empty("C:/okay_language_engine/python-arm64"):
			$"PanelContainer/Control/VBoxContainer/arm".text = "ARM64（已安装）"
			barm = true
		if Global.is_folder_exist_and_not_empty("C:/okay_language_engine/python-win32"):
			$"PanelContainer/Control/VBoxContainer/32".text = "WIN-32bit（已安装）"
			b32 = true

func _on_b64_pressed() -> void:
	if not b64:
		Global.target_version = "amd64"
		var dialog = ConfirmationDialog.new()
		dialog.cancel_button_text = "取消"
		dialog.ok_button_text = "确定"
		dialog.dialog_text = "是否下载解释器？\n确定后将在后台下载x86_64(amd64)架构解释器！\n下载时请不要关闭软件程序。\n下载过程会在主页面控制台显示，请留意。"
		dialog.title = "下载解释器"
		dialog.confirmed.connect(func():Global.start_download(Global.python_amd64,'python'))
		add_child(dialog)
		dialog.popup_centered()
	else:
		Global.currently_python_interpreter = Global.get_interpreter_config("amd64")+"/python.exe"
		Global.set_interpreter_config("currently_version","amd64")
	$PanelContainer/Control/VBoxContainer/Content.text = "选择你的代码解释器架构：\n（当前："+Global.currently_python_interpreter+"）"
	Global.send_output.emit("成功修改代码解释器架构为："+Global.currently_python_interpreter)

func _on_b32_pressed() -> void:
	if not b32:
		Global.target_version = "win32"
		var dialog = ConfirmationDialog.new()
		dialog.cancel_button_text = "取消"
		dialog.ok_button_text = "确定"
		dialog.dialog_text = "是否下载解释器？\n确定后将在后台下载x86-32架构解释器！\n下载时请不要关闭软件程序。\n下载过程会在主页面控制台显示，请留意。"
		dialog.title = "下载解释器"
		dialog.confirmed.connect(func():Global.start_download(Global.python_win32,'python'))
		add_child(dialog)
		dialog.popup_centered()
	else:
		Global.currently_python_interpreter = Global.get_interpreter_config("win32")+"/python.exe"
		Global.set_interpreter_config("currently_version","win32")
	$PanelContainer/Control/VBoxContainer/Content.text = "选择你的代码解释器架构：\n（当前："+Global.currently_python_interpreter+"）"
	Global.send_output.emit("成功修改代码解释器架构为："+Global.currently_python_interpreter)
	
func _on_barm_pressed() -> void:
	if not barm:
		Global.target_version = "arm64"
		var dialog = ConfirmationDialog.new()
		dialog.cancel_button_text = "取消"
		dialog.ok_button_text = "确定"
		dialog.dialog_text = "是否下载解释器？\n确定后将在后台下载ARM64架构解释器！\n下载时请不要关闭软件程序。\n下载过程会在主页面控制台显示，请留意。"
		dialog.title = "下载解释器"
		dialog.confirmed.connect(func():Global.start_download(Global.python_arm64,'python'))
		add_child(dialog)
		dialog.popup_centered()
	else:
		Global.currently_python_interpreter = Global.get_interpreter_config("arm64")+"/python.exe"
		Global.set_interpreter_config("currently_version","arm64")
	$PanelContainer/Control/VBoxContainer/Content.text = "选择你的代码解释器架构：\n（当前："+Global.currently_python_interpreter+"）"
	Global.send_output.emit("成功修改代码解释器架构为："+Global.currently_python_interpreter)
