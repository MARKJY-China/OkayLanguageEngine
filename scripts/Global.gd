extends Node
class_name global

signal send_output(content,mode)
signal send_progress_output(content)
signal is_extract

var currently_file_path = null
var last_currently_file_path = null
var config_file_path = "user://ole_config.ini"
var active_files = []

var target_directory: String = "C:/okay_language_engine/python"       # 解压目标目录
var target_version: String = "amd64"
var _download_url = ""
var http_request: HTTPRequest

# 后台线程和进度跟踪
var download_thread: Thread
var is_downloading: bool = false
var last_progress_update_time: int = 0

var currently_python_interpreter = null
var python_amd64 = "https://pan.aymao.com/f/eeZFe/python-amd64.zip"
var python_win32 = "https://pan.aymao.com/f/gDkSE/python-win32.zip"
var python_arm64 = "https://pan.aymao.com/f/E7KtL/python-3.13.7-embed-arm64.zip"

# 定义关键字列表
var a_keywords :=    ["如果", "否则", '否则如果',"条件循环","有序循环","退出","继续","省略","那么",]
var a_keywords_en := ["if","else","elif","while","for","break","continue","pass",":"]
var b_keywords :=    ["真", "假", "空"]
var b_keywords_en := ["True","False","None"]
var c_keywords :=    ["和", "或", "不是", "里", "是"]
var c_keywords_en := ["and","or","not","in","is"]
var d_keywords :=    ["函数","类","返回","导入","来自","产出"]
var d_keywords_en := ["def","class","break","import","from","yield"]
var e_keywords :=    ["字符型","整数型","布尔型","浮点型"]
var e_keywords_en := ["str","int","bool","float"]
var a_functions :=   ["打印","字符化","整数化","布尔化","浮点化","取长度","区间","输入"]
var a_functions_en :=["print","str","int","bool","float","len","range","input"]


# 拼音映射表：拼音 -> 中文关键字
var pinyin_map := {
	"dayin": "打印",
	"ruguo": "如果",
	"fouze": "否则",
	"jieshu": "结束",
	"hanshu": "函数",
	"daoru": "导入",
	"fanhui": "返回",
	"zhen": "真",
	"jia": "假",
	"he": "和",
	"huo": "或",
	"kong":"空",
	"bushi":"不是",
	"jixu":"继续",
	"tuichu":"退出",
	"li":"里",
	"shi":"是",
	"zifuxing": "字符型",
	"zhengshuxing": "整数型",
	"buerxing": "布尔型",
	"fudianxing": "浮点型",
	"youxuxunhuan":"有序循环",
	"tiaojianxunhuan":"条件循环",
	"shenglue":"省略",
	"zifuhua":"字符化",
	"zhengshuhua":"整数化",
	"quchangdu":"取长度",
	"qujian":"区间",
	"changchu":"产出",
	"lei":"类",
	"laizi":"来自",
	"name":"那么",
	"input":"输入",
	
	# 简拼
	#"dy": "打印",
	#"rg": "如果",
	#"fz": "否则",
	#"js": "结束",
	#"hs": "函数",
	#"brx": "布尔型",
	#"fdx": "浮点型",
	#"zfx": "字符型",
	#"zsx": "整数型",
	#"dr": "导入",
	#"yxxh": "有序循环",
	#"tjxh": "条件循环",
	#"sl":"省略",
}

# 函数拼音映射表
var function_pinyin := {
	"主函数": "zhuhanshu",
	#"循环": "xunhuan",
	"输入": "shuru",
	"随机数": "suijishu"
}

var python_path: String = ""

func _ready() -> void:
	if not is_folder_exist_and_not_empty("C:/okay_language_engine"):
		DirAccess.make_dir_absolute("C:/okay_language_engine")
	if get_interpreter_config("currently_version"):
		currently_python_interpreter = get_interpreter_config(get_interpreter_config("currently_version"))+"/python.exe"
	python_path = _get_python_path()
	if currently_file_path == null:
		currently_file_path == "C:/okay_lang_1.okpy"

func show_confirmation_dialog(title:String="提示",content:String="提示内容",ok_button_text:String="确定",cancel_button_text:String="取消"):
	var dialog = ConfirmationDialog.new()
	dialog.cancel_button_text = cancel_button_text
	dialog.ok_button_text = ok_button_text
	dialog.dialog_text = content
	dialog.title = title
	get_node("/root/Main").add_child(dialog)
	dialog.popup_centered()

func save_file(content, path) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file.store_string(content):
		currently_file_path = path
	else:
		return false
	return true
	
func load_file(path) -> String:
	if not path:
		return ""
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return "" 
	var content = file.get_as_text()
	file.close()
	currently_file_path = path
	return content
	
func delete_file(file_path: String = currently_file_path) -> bool:
	# 检查文件是否存在
	if FileAccess.file_exists(file_path):
		if DirAccess.open(file_path.get_base_dir()).remove(file_path.get_file()) == OK:
			return true
		else:
			return false
	else:
		print("文件不存在: ", file_path)
		return false
		
func delete_directory_contents(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()  # 开始遍历目录
		var file_name := dir.get_next()
		while file_name != "":
			var full_path := path.path_join(file_name)
			if dir.current_is_dir():
				# 递归删除子目录
				delete_directory_contents(full_path)
				dir.remove(full_path)  # 删除空目录
			else:
				dir.remove(full_path)  # 删除文件
			file_name = dir.get_next()
		dir.list_dir_end()  # 结束遍历
		is_extract.emit()
	else:
		push_error("无法打开目录: " + path)
		
func is_folder_exist_and_not_empty(path: String) -> bool:
	var dir = DirAccess.open(path)
	if not dir:
		return false  # 文件夹不存在或无法访问
	
	dir.list_dir_begin()  # 开始遍历目录
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			dir.list_dir_end()  # 结束遍历
			return true  # 发现非空项
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return false  # 文件夹为空
	
func get_project_version() -> String:
	return ProjectSettings.get_setting("application/config/version", "unknown")
	
func get_system_architecture() -> String:
	var arch = Engine.get_architecture_name()
	
	match arch:
		"x86_64", "x86_64-v2", "x86_64-v3":
			return "amd64"
		"x86_32":
			return "win32"
		"arm64", "arm64-v8a":
			return "arm64"
		_:
			return "unknown"
	
var download_mode = 'python'
func start_download(download_url:String,mode:String):
	if is_downloading:
		return
	download_mode = mode
	if mode == 'python':
		is_downloading = true
		_download_url = download_url
		target_directory = "C:/okay_language_engine/python-"+target_version
		_getnode("/root/Main/http")
		_download_in_thread()
	elif mode == 'update':
		is_downloading = true
		_download_url = download_url
		target_directory = "C:/okay_language_engine/new_version"
		_getnode("/root/Main/http")
		_download_in_thread()
	return
	# 在后台线程中启动下载
	download_thread = Thread.new()
	download_thread.start(_download_in_thread)
		
func _getnode(path):
	http_request = get_node(path)
	return get_node(path)
		
# 后台线程中的下载任务
func _download_in_thread():
	send_output.emit("正在发起下载请求...请勿关闭程序！（可能需要3分钟）")
	http_request.request_completed.connect(_on_download_completed)
	
	# 发起请求（注意：HTTPRequest 必须在主线程调用）
	call_deferred("_deferred_start_download", http_request)
	
# 主线程中触发下载（HTTPRequest 的限制）
func _deferred_start_download(http_request: HTTPRequest):
	var error = http_request.request(_download_url)
	if error != OK:
		push_error("下载请求失败，错误码: " + str(error))
		send_output.emit(get_hint_text('Error')+"下载请求失败，错误码: " + str(error))
		is_downloading = false
		
# 下载进度更新（通过 _process 轮询）
func _process(delta):
	if !is_downloading:
		return
	
	var http_request = get_node("/root/Main/http")
	if http_request.get_http_client_status() == HTTPClient.STATUS_BODY:
		# 限制进度更新频率（每秒最多 10 次）
		var now = Time.get_ticks_msec()
		if now - last_progress_update_time > 50:
			var downloaded_bytes = http_request.get_downloaded_bytes()
			var total_bytes = http_request.get_body_size()
			
			if total_bytes > 0:
				var percent = float(downloaded_bytes) / total_bytes * 100
				var information = "[color=yellow]下载中[/color]: %.1f%% (%s/%s)" % [
					percent,
					_format_bytes(downloaded_bytes),
					_format_bytes(total_bytes)
				]
				send_progress_output.emit(information)
			last_progress_update_time = now

func _on_download_completed(result, response_code, headers, body):
	if download_mode == 'python':
		send_output.emit(get_hint_text('')+"解释器安装包即将下载完成！")
	elif download_mode == 'update':
		pass
	is_downloading = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		send_output.emit(get_hint_text('Error')+"下载失败: " + str(result))
		return
	
	var temp_path = "C:/okay_language_engine/temp_download.zip"
	var new_version_file = "C:/okay_language_engine/new_version/OkayLanguageEngine.exe"
	if download_mode == 'python':
		var file = FileAccess.open(temp_path, FileAccess.WRITE)
		if file:
			file.store_buffer(body)
			file.close()
			download_thread = Thread.new()
			if download_thread.is_started():
				download_thread.wait_to_finish()
			download_thread.start(_extract_in_thread.bind(temp_path))
		else:
			send_output.emit(Global.get_hint_text('Error')+"解释器-无法保存文件")
	elif download_mode == 'update':
		if not is_folder_exist_and_not_empty(new_version_file.get_base_dir()):
			DirAccess.make_dir_recursive_absolute(new_version_file.get_base_dir())
		var file = FileAccess.open(new_version_file, FileAccess.WRITE)
		if file:
			file.store_buffer(body)
			file.close()
			send_output.emit(get_hint_text('')+"OkayLanguageEngine（欧克语言引擎）最新版本下载完成！\n"+get_hint_text('')+"最新版本已下载到："+new_version_file)
		else:
			send_output.emit(Global.get_hint_text('Error')+"版本更新-无法保存文件")
		
		
# 后台线程中的解压任务
func _extract_in_thread(zip_path: String):
	var zip_reader = ZIPReader.new()
	if zip_reader.open(zip_path) == OK:
		var files = zip_reader.get_files()
		for i in files.size():
			var file_path = files[i]
			var file_data = zip_reader.read_file(file_path)
			
			# 主线程中更新解压进度
			call_deferred("_update_extract_progress", i, files.size())
			
			# 写入文件
			var full_path = target_directory.path_join(file_path)
			DirAccess.make_dir_recursive_absolute(full_path.get_base_dir())
			var output_file = FileAccess.open(full_path, FileAccess.WRITE)
			if output_file:
				output_file.store_buffer(file_data)
				output_file.close()
		
		zip_reader.close()
		DirAccess.remove_absolute(zip_path)
		call_deferred("_on_extract_complete")
	else:
		call_deferred("_on_extract_failed")

# 主线程中更新解压进度
func _update_extract_progress(current: int, total: int):
	var percent = float(current) / total * 100
	send_progress_output.emit("[color=yellow]安装进度：[/color]解释器安装中: %.1f%% (%d/%d)" % [percent, current, total])

func _on_extract_complete():
	send_output.emit("[color=green]✓[/color]安装完成！文件保存在: " + target_directory)
	print("[color=green]✓[/color]解压完成！文件保存在: " + target_directory)
	send_output.emit("[color=green]✓[/color]解释器安装完成（"+target_directory+"）！已自动选择该解释器用于运行编译")
	currently_python_interpreter = target_directory+"/python.exe"
	set_interpreter_config(target_version,target_directory)
	set_interpreter_config("currently_version",target_version)
	is_extract.emit()
	if download_thread.is_started():
		download_thread.wait_to_finish()

func _on_extract_failed():
	send_output.emit("安装：安装失败！请检查 ZIP 文件")
	if download_thread.is_started():
		download_thread.wait_to_finish()

# 解压 ZIP 文件
func extract_zip(zip_path, extract_to):
	# 使用 ZIPReader 解压
	send_output.emit("安装：将使用 ZIPReader 解压")
	var zip_reader = ZIPReader.new()
	if zip_reader.open(zip_path) == OK:
		# 获取 ZIP 中的所有文件
		send_output.emit("安装：正在获取 ZIP 中的所有文件,开始安装")
		var files = zip_reader.get_files()
		for file_path in files:
			# 读取文件内容
			#send_output.emit("安装：正在读取文件内容")
			var file_data = zip_reader.read_file(file_path)
			if file_data.size() > 0:
				# 构建完整的目标路径
				var full_path = extract_to.path_join(file_path)
				var dir_path = full_path.get_base_dir()
				
				# 确保目录存在
				#send_output.emit("安装：正在检测目录是否存在")
				DirAccess.make_dir_recursive_absolute(dir_path)
				
				# 写入文件
				#send_output.emit("安装：正在写入文件")
				var output_file = FileAccess.open(full_path, FileAccess.WRITE)
				if output_file:
					output_file.store_buffer(file_data)
					output_file.close()
		
		zip_reader.close()
		print("解压完成！文件保存在: " + extract_to)
		send_output.emit("安装：解释器安装完成（"+extract_to+"）！已自动选择该解释器用于运行编译")
		currently_python_interpreter = extract_to+"/python.exe"
		set_interpreter_config(target_version,extract_to)
		set_interpreter_config("currently_version",target_version)
		is_extract.emit()
		
		# 删除临时 ZIP 文件
		DirAccess.remove_absolute(zip_path)
	else:
		push_error("ZIP 文件打开失败")
		send_output.emit("安装：ZIP 文件打开失败")
		
# 辅助函数：格式化字节大小
func _format_bytes(bytes: int) -> String:
	var units = ["B", "KB", "MB", "GB"]
	var unit_index = 0
	var size = float(bytes)
	
	while size > 1024 and unit_index < units.size() - 1:
		size /= 1024
		unit_index += 1
	
	return "%.1f %s" % [size, units[unit_index]]
	
func get_hint_text(type) -> String:
	if type == 'Error':
		return "[color=red]✕[/color]"
	elif type == 'Warning':
		return "[color=yellow]‣[/color]"
	elif type == "Info":
		return "[color=blue]¡[/color]"
	else:
		return "[color=green]✓[/color]"
	
func get_window_config(window:String):
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		return config.get_value("window",window,"not_load")
	return "not_load"
	
func set_window_config(window:String,visible:bool):
	var config = ConfigFile.new()
	config.load(config_file_path)
	config.set_value("window",window,visible)
	config.save(config_file_path)
	
func get_uisettings_config(key:String):
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		return config.get_value("ui_settings",key,"not_load")
	return "not_load"
	
func set_uisettings_config(key:String,val):
	var config = ConfigFile.new()
	config.load(config_file_path)
	config.set_value("ui_settings",key,val)
	return config.save(config_file_path)
	
func get_interpreter_config(key:String):
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		return config.get_value("interpreter",key,"not_load")
	return "not_load"
	
func set_interpreter_config(key:String,val):
	var config = ConfigFile.new()
	config.load(config_file_path)
	config.set_value("interpreter",key,val)
	config.save(config_file_path)
	
#设置最后一次使用的是文件管理器中的哪个文件
func set_filesmanager_currfile_config(file_path:String):
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		config.set_value("FilesManager","last_currfile",file_path)
		config.save(config_file_path)
	return true
	
func get_filesmanager_currfile_config():
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		if typeof(config.get_value("FilesManager","last_currfile",false)) == TYPE_STRING:
			return config.get_value("FilesManager","last_currfile",false)
	return 'not_load'
	
#添加文件管理器中的活跃文件
func add_filesmanager_config(file_path:String):
	print(file_path)
	var config = ConfigFile.new()
	var file_array = []
	if config.load(config_file_path) == OK:
		if not config.get_value("FilesManager","files",false):
			file_array = [file_path]
		else:
			file_array = config.get_value("FilesManager","files")
			file_array.append(file_path)
	config.set_value("FilesManager","files",file_array)
	config.save(config_file_path)
	return true
	
func remove_filesmanager_config(file_path:String):
	print(file_path)
	var config = ConfigFile.new()
	var file_array = []
	if config.load(config_file_path) == OK:
		if not config.get_value("FilesManager","files",false):
			return false
		else:
			file_array = config.get_value("FilesManager","files")
			file_array.remove_at(active_files.find(file_path))
	config.set_value("FilesManager","files",file_array)
	config.save(config_file_path)
	return true
	
func get_filesmanager_config():
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		return config.get_value("FilesManager","files",[])
	return []
	
func set_last_currently_file(path:String=currently_file_path) -> bool:
	if path != null:
		last_currently_file_path = path
		var config = ConfigFile.new()
		config.load(config_file_path)
		config.set_value("basic","last_currently_file",path)
		config.save(config_file_path)
	else:
		return false
	return true

func get_path_file(path:String=currently_file_path) -> String:
	if path != null:
		return path.get_file()
	return ""

func check_file_save(code_edit: CodeEdit) -> bool:
	if code_edit.text != load_file(currently_file_path):
		return false
	return true
	
# 获取Python可执行文件路径
func _get_python_path() -> String:
	# 在编辑器中使用res://路径
	if OS.has_feature("editor"):
		return "python/python.exe"
	
	# 在导出版本中使用相对路径
	var exe_dir = OS.get_executable_path().get_base_dir()
	return exe_dir.path_join("python/python.exe")

func compile_code(code: String) -> String:
	# 将中文关键字替换为Python关键字
	var python_code = code
	
	# 替换关键字
	for i in a_keywords.size():
		python_code = python_code.replace(a_keywords[i], a_keywords_en[i])
	for i in b_keywords.size():
		python_code = python_code.replace(b_keywords[i], b_keywords_en[i])
	for i in c_keywords.size():
		python_code = python_code.replace(c_keywords[i], c_keywords_en[i])
	for i in d_keywords.size():
		python_code = python_code.replace(d_keywords[i], d_keywords_en[i])
	for i in e_keywords.size():
		python_code = python_code.replace(e_keywords[i], e_keywords_en[i])
	for i in a_functions.size():
		python_code = python_code.replace(a_functions[i], a_functions_en[i])
	
	# 添加必要的导入
	if "random.randint" in python_code:
		python_code = "import random\n" + python_code
	
	python_code = """
import sys
import time
import os

sys.stdout.reconfigure(line_buffering=True)
def input(prompt=""):
	print(prompt, end="")
	# 写入输入请求文件
	with open("C:/okay_language_engine/temp_input_request.txt", "w", encoding="utf-8") as f:
		f.write(prompt)
	# 等待输入结果
	while not os.path.exists("C:/okay_language_engine/temp_input_result.txt"):
		time.sleep(0.1)
	with open("C:/okay_language_engine/temp_input_result.txt", "r", encoding="utf-8") as f:
		result = f.read()
	os.remove("C:/okay_language_engine/temp_input_result.txt")
	return result\n\n\n
##---OkayLanguage部分---\n
"""+python_code
	
	return python_code

# 运行编译后的代码
func run_compiled_code(python_code: String) -> void:
	# 创建临时文件
	var temp_file = "user://temp_script.py"
	var file = FileAccess.open(temp_file, FileAccess.WRITE)
	file.store_string(python_code)
	file.close()
	
	# 检查Python路径是否有效
	if not FileAccess.file_exists(currently_python_interpreter):
		send_output.emit(get_hint_text('Error')+"错误: Python解释器未找到: " + currently_python_interpreter)
		return
	
	# 执行Python脚本
	var output = []
	
	var exit_code = OS.execute(currently_python_interpreter, [ProjectSettings.globalize_path(temp_file)], output)
	
	# 显示输出结果
	if exit_code == 0:
		print("执行成功")
		send_output.emit(get_hint_text('')+"运行成功:")
		var i = 0
		for line in output[0].split('\n'):
			if i == output.size():
				return
				
			if i == 0:
				send_output.emit('>>>'+line)
			else:
				send_output.emit('>>>'+line,2)
			i += 1
	else:
		send_output.emit(get_hint_text('Warning')+"[color=yellow]脚本已退出[/color]，返回码: "+str(exit_code)+"|Python解释器路径："+python_path)
		for line in output:
			send_output.emit('>>>'+line)
			print(line)
