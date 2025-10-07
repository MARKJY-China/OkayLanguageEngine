extends Control

signal custom_button_pressed

##主要组件
@onready var file_dialog: FileDialog = $"FileDialog"
@onready var code_edit: CodeEdit = $"IDE-Center/Margin/Code/Work/CodeEdit"
@onready var status: Label = $"IDE-Center/Margin/Code/TopBar_BG/TopBar/Status"
@onready var file_manager_pc: PanelContainer = $"IDE-Center/Margin/Code/Work/PC"
@onready var file_manager: VBoxContainer = $"IDE-Center/Margin/Code/Work/PC/FileManager"
@onready var file_0: Button = $"IDE-Center/Margin/Code/Work/PC/FileManager/File0"
##MenuButton组件
@onready var mb_file: MenuButton = $"IDE-Center/Margin/Code/TopBar_BG/TopBar/File"
@onready var mb_window: MenuButton = $"IDE-Center/Margin/Code/TopBar_BG/TopBar/Window"
@onready var mb_build: MenuButton = $"IDE-Center/Margin/Code/TopBar_BG/TopBar/Build"
@onready var mb_settings: MenuButton = $"IDE-Center/Margin/Code/TopBar_BG/TopBar/Settings"
@onready var mb_more: MenuButton = $"IDE-Center/Margin/Code/TopBar_BG/TopBar/More"
@onready var console_pc: PanelContainer = $"IDE-Center/Margin/Code/Console_PC"
@onready var console: RichTextLabel = $"IDE-Center/Margin/Code/Console_PC/MarginContainer/Console"
@onready var mb_console: MenuButton = $"IDE-Center/Margin/Code/TopBar_BG/TopBar/Console"

var currently_filedialog_mode = 0
var menu: PopupMenu   

func _ready() -> void:
	
	mb_file.get_popup().connect("id_pressed",menubutton_file_pressed)
	mb_window.get_popup().connect("id_pressed",menubutton_window_pressed)
	mb_build.get_popup().connect("id_pressed",menubutton_build_pressed)
	mb_settings.get_popup().connect("id_pressed",menubutton_settings_pressed)
	mb_more.get_popup().connect("id_pressed",menubutton_more_pressed)
	mb_console.get_popup().connect("id_pressed",menubutton_console_pressed)
	
	##FileButton右键菜单
	# 1. 准备菜单
	menu = PopupMenu.new()
	add_child(menu)                       # 必须进树才能显示
	menu.add_item("关闭", 1)
	menu.add_separator()
	menu.add_item("删除", 0)
	menu.id_pressed.connect(_on_filebutton_menu_click)
	
	Global.send_output.connect(_add_output)
	Global.send_progress_output.connect(_add_progress_output)
	var 本地数据是否有记录最后一次打开的文件 = false
	if Global.get_filesmanager_currfile_config() != 'not_load':
		本地数据是否有记录最后一次打开的文件 = true
		Global.currently_file_path = Global.get_filesmanager_currfile_config()
	if Global.get_filesmanager_config() != []:
		Global.active_files = Global.get_filesmanager_config()
		var i = 0
		for file_path in Global.active_files:
			if i == 0 :
				file_0.text = file_path.get_file()
				if not 本地数据是否有记录最后一次打开的文件:
					Global.currently_file_path = file_path
					file_0.text = '>'+file_path.get_file()
				file_0.show()
				file_0.mouse_filter = Control.MOUSE_FILTER_PASS
				file_0.gui_input.connect(_on_filebutton_gui_input.bind(file_0))
			else:
				var file_button = Button.new()
				file_button.name = "File"+str(i)
				file_button.theme = load("res://theme.tres")
				file_button.add_theme_font_size_override("font_size",14)
				file_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				file_button.gui_input.connect(_on_filebutton_gui_input.bind(file_button))
				file_manager.add_child(file_button)
			var filen = "/root/Main/IDE-Center/Margin/Code/Work/PC/FileManager/File"+str(i)
			if file_path == Global.get_filesmanager_currfile_config():
				get_node(filen).text = '>'+file_path.get_file()
			else:
				get_node(filen).text = file_path.get_file()
			get_node(filen).connect("pressed",func():_on_file_button_pressed(i))
			status.text = Global.currently_file_path.get_file()
			i += 1
			
	
	var version = Global.get_project_version()
	console.text = "OkayLanguageEngine v"+version+" By MARKJY"
	
	var highlighter = preload('res://scripts/oklang_high_lighter.gd').new()
	code_edit.syntax_highlighter = highlighter
	var config = ConfigFile.new()
	if config.load(Global.config_file_path) == OK:
		if Global.currently_file_path != null:
			code_edit.text = Global.load_file(Global.currently_file_path)
			status.text = Global.currently_file_path.get_file()
			if Global.get_window_config("file_manager"): file_manager_pc.show()
			else: file_manager_pc.hide()
			if Global.get_window_config("console"): console_pc.show()
			else: console_pc.hide()
			if typeof(Global.get_uisettings_config("console_font_size")) == TYPE_FLOAT: console.add_theme_font_size_override("normal_font_size",Global.get_uisettings_config("console_font_size"))

func _on_open_pressed() -> void:
	currently_filedialog_mode = 0
	file_dialog.title = "从指定位置打开文件"
	file_dialog.ok_button_text = "打开"
	file_dialog.file_mode = 0
	file_dialog.show()

func _on_save_pressed() -> void:
	currently_filedialog_mode = 4
	if Global.currently_file_path == null:
		file_dialog.title = "保存文件到指定位置"
		file_dialog.ok_button_text = "保存"
		file_dialog.add_filter("*.okpy ; Okay中文Python文件")
		file_dialog.add_filter("*.txt ; 纯文本文档")
		file_dialog.file_mode = 4
		file_dialog.show()
	else:
		Global.save_file(code_edit.text,Global.currently_file_path)
		_on_code_edit_text_changed()

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_about_pressed() -> void:
	$About.show()


func _on_file_dialog_file_selected(path: String) -> void:
	if file_dialog.file_mode == 4:
		Global.save_file(code_edit.text,path)
		status.text = path.get_file()
		Global.active_files.append(path)
		Global.add_filesmanager_config(path)
	elif file_dialog.file_mode == 0:
		if path in Global.active_files:
			var dialog = ConfirmationDialog.new()
			dialog.get_cancel_button().hide()
			dialog.ok_button_text = "好的"
			dialog.dialog_text = "该文件已打开在文件管理器"
			dialog.title = "提示"
			add_child(dialog)
			dialog.popup_centered()
			return
		Global.set_filesmanager_currfile_config(path)
		code_edit.text = Global.load_file(path)
		status.text = path.get_file()
		Global.currently_file_path = path
		Global.active_files.append(path)
		Global.add_filesmanager_config(path)
	reflash_files_list()
	
var now_btn: Button
func _on_filebutton_gui_input(ev: InputEvent,btn:Button):
	# 右键按下
	if ev is InputEventMouseButton \
	   and ev.button_index == MOUSE_BUTTON_RIGHT \
	   and ev.pressed:
		# 把局部坐标转成全局
		var gp = btn.get_global_transform() * ev.position
		# 弹出，大小自动
		menu.popup(Rect2(gp, Vector2.ZERO))
		now_btn = btn
	
func _on_filebutton_menu_click(id: int):
	match id:
		1: 
			print("关闭")
			if now_btn is Button and now_btn.name.begins_with("File"):  # 确保是 Button 类型
				var number_str = now_btn.name.trim_prefix("File")
				var number = number_str.to_int()  # 转换为整数
				Global.active_files.remove_at(number)
				reflash_files_list()

		0: print("删除")

func _on_code_edit_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_file"):
		_on_save_pressed()

func _on_code_edit_text_changed() -> void:
	if Global.currently_file_path != null:
		if (not check_file_save(Global.currently_file_path)):
			if (status.text.find("*") == -1):
				status.text = "*"+status.text
		else:
			status.text = Global.currently_file_path.get_file()
			
func _on_file_button_pressed(id:int):
	var children = file_manager.get_children()  # 获取所有子节点
	var button = get_node("IDE-Center/Margin/Code/Work/PC/FileManager/File"+str(id))
	for i in children.size():
		var child = children[i]
		if child is Button and child.name.begins_with("File"):  # 确保是 Button 类型
			var number_str = child.name.trim_prefix("File")
			var number = number_str.to_int()  # 转换为整数
			child.text = Global.active_files[number].get_file()
			Global.set_filesmanager_currfile_config(Global.active_files[number])
	status.text = button.text
	button.text = ">"+button.text
	code_edit.text = Global.load_file(Global.active_files[id])

func check_file_save(path: String) -> bool:
	if code_edit.text != Global.load_file(path):
		return false
	return true

func reflash_files_list():
	if Global.get_filesmanager_config() != []:
		Global.active_files = Global.get_filesmanager_config()

		var children = file_manager.get_children()  # 获取所有子节点
		# 从第3个开始删除（索引2）
		for a in range(2, children.size()):
			var child = children[a]
			if child is Button:  # 确保是 Button 类型
				child.queue_free()  # 安全删除

		print(children)
		var i = 0
		for file_path in Global.active_files:
			if i == 0 :
				file_0.text = file_path.get_file()
				file_0.show()
			else:
				var file_button = Button.new()
				file_button.theme = load("res://theme.tres")
				file_button.add_theme_font_size_override("font_size",14)
				file_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				file_button.text = file_path.get_file()
				file_button.connect("pressed",func():_on_file_button_pressed(i))
				file_manager.add_child(file_button)
				print(file_button.get_path())
			var filen = "IDE-Center/Margin/Code/Work/PC/FileManager/File"+str(i)
			#如果遍历到的该文件对应我现在使用的文件则设置列表显示的按钮加多一个>
			if Global.currently_file_path == file_path:
				get_node(filen).text = ">"+file_path.get_file()
			i += 1
		var child_i = 0
		for child in file_manager.get_children():
			if child is Button and child.name.find('File') != -1 and child.name != 'File0':
				child.name = 'File'+str(child_i)
				print("按钮名称:", child.name, "文本:", child.text)
			child_i += 1

			
func remove_files_list(id:int):
	var children = file_manager.get_children()  # 获取所有子节点
	var child = children[id]
	child.queue_free()

func menubutton_file_pressed(id:int):
	match id:
		0:
			_on_open_pressed()
		1:
			_on_save_pressed()
		2:
			file_dialog.title = "保存文件到指定位置"
			file_dialog.ok_button_text = "保存"
			file_dialog.file_mode = 4
			file_dialog.add_filter("*.okpy ; Okay中文Python文件")
			file_dialog.add_filter("*.txt ; 纯文本文档")
			file_dialog.show()
		3:
			if Global.currently_file_path != null:
				if code_edit.text != "":
					#Global.show_confirmation_dialog("确定吗？","当前文件不为空，确定永久删除？")
					var dialog = ConfirmationDialog.new()
					dialog.cancel_button_text = "不删除"
					dialog.ok_button_text = "确定"
					dialog.dialog_text = "当前文件不为空，确定永久删除？"
					dialog.title = "确定吗？"
					dialog.confirmed.connect(Global.delete_file)
					dialog.confirmed.connect(func():code_edit.text = "")
					dialog.confirmed.connect(func():remove_files_list(Global.active_files.find(Global.currently_file_path)+1))
					dialog.confirmed.connect(func():Global.remove_filesmanager_config(Global.currently_file_path))
					dialog.confirmed.connect(func():Global.currently_file_path = null)
					dialog.confirmed.connect(func():status.text = "*新文件.txt")
					dialog.confirmed.connect(func():Global.active_files.remove_at(Global.active_files.find(Global.currently_file_path)))
					add_child(dialog)
					dialog.popup_centered()
				else:
					Global.delete_file()
					code_edit.text = ""
					status.text = "*未知文件.okpy"
					Global.currently_file_path = null
		4:
			$CreateNewFile.show()
				
			
func menubutton_window_pressed(id:int):
	match id:
		0:
			if file_manager_pc.visible:
				mb_window.get_popup().set_item_text(0,"显示文件管理器")
				file_manager_pc.hide()
				Global.set_window_config("file_manager",false)
			else:
				mb_window.get_popup().set_item_text(0,"隐藏文件管理器")
				file_manager_pc.show()
				Global.set_window_config("file_manager",true)
		1:
			if console_pc.visible:
				mb_window.get_popup().set_item_text(1,"显示控制台")
				console_pc.hide()
				Global.set_window_config("console",false)
			else:
				mb_window.get_popup().set_item_text(1,"隐藏控制台")
				console_pc.show()
				Global.set_window_config("console",true)
	
func menubutton_build_pressed(id:int):
	match id:
		0:
			$Builder.show()
		1:
			if Global.currently_file_path != null:
				if Global.currently_file_path.get_file().get_extension() != "okpy":
					var dialog = ConfirmationDialog.new()
					dialog.cancel_button_text = "取消"
					dialog.ok_button_text = "知道了"
					dialog.dialog_text = "当前文件不是欧克中文编程引擎的代码文件（*.okpy）无法运行。"
					dialog.title = "文件不符合"
					add_child(dialog)
					dialog.popup_centered()
					return
			else:
				var dialog = ConfirmationDialog.new()
				dialog.cancel_button_text = "取消"
				dialog.ok_button_text = "噢噢，好的"
				dialog.dialog_text = "当前文件未保存，无法运行代码"
				dialog.title = "错误"
				add_child(dialog)
				dialog.popup_centered()
			if Global.currently_python_interpreter == null:
				var dialog = ConfirmationDialog.new()
				dialog.cancel_button_text = "取消"
				dialog.ok_button_text = "选择解释器"
				dialog.dialog_text = "您还没有选择解释器，请选择代码解释器再运行"
				dialog.title = "解释器未选择"
				dialog.confirmed.connect(func():$Interpreter.show())
				add_child(dialog)
				dialog.popup_centered()
				return
			var code = code_edit.text
			var py_code = Global.compile_code(code)
			Global.run_compiled_code(py_code)
	
func menubutton_settings_pressed(id:int):
	match id:
		0:
			$UISettings.show()
		1:
			$Interpreter.show()
		2:
			var dialog = ConfirmationDialog.new()
			dialog.cancel_button_text = "取消"
			dialog.ok_button_text = "确定"
			dialog.dialog_text = "你确定清空所有本软件的数据吗？\n确认后则清空且无法恢复"
			dialog.title = "确定清空所有数据？"
			dialog.confirmed.connect(func():Global.delete_directory_contents("C:/okay_language_engine"))
			dialog.confirmed.connect(func():Global.delete_file("user://ole_config.ini"))
			add_child(dialog)
			dialog.popup_centered()
	
func menubutton_more_pressed(id:int):
	match id:
		0:
			_on_about_pressed()
		1:
			_on_quit()
		2:
			get_new_version()
			
func menubutton_console_pressed(id:int):
	match id:
		0:
			console.clear()

func _on_run_pressed() -> void:
	pass # Replace with function body.


func _on_compile_pressed() -> void:
	pass # Replace with function body.

var http_request: HTTPRequest
func get_new_version():
	var main = get_node("/root/Main")
	http_request = HTTPRequest.new()
	main.add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	fetch_text("http://ole.markjy.com/version.txt")
	
# 发起HTTP GET请求获取文本内容
func fetch_text(url: String):
	var errors = http_request.request(url)
	if errors != OK:
		Global.send_output.emit(Global.get_hint_text("Error")+"HTTP请求创建失败: " + str(errors))
		return null

var url = []
# 请求完成回调
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		Global.send_output.emit(Global.get_hint_text("Error")+"HTTP请求失败，错误代码: " + str(result))
		return
	
	if response_code != 200:
		Global.send_output.emit(Global.get_hint_text("Error")+"HTTP响应错误，状态码: " + str(response_code))
		return
	
	# 将字节数组转换为字符串
	var text_content = body.get_string_from_utf8()
	url = text_content.split('\n')
	if int(text_content.split("\n")[0]) >= int(Global.get_project_version()):
		var dialog = ConfirmationDialog.new()
		dialog.get_cancel_button().hide()
		dialog.ok_button_text = "明白"
		dialog.dialog_text = "当前版本已经是最新版了。"
		dialog.title = "无需更新"
		add_child(dialog)
		dialog.popup_centered()
	else:
		var dialog = ConfirmationDialog.new()
		dialog.cancel_button_text = "取消"
		dialog.ok_button_text = "立即更新"
		var custom_button = Button.new()
		custom_button.text = "自助更新"
		dialog.get_ok_button().get_parent().add_child(custom_button)
		dialog.get_ok_button().get_parent().move_child(custom_button, dialog.get_ok_button().get_index())
		custom_button.pressed.connect(_on_custom_button_pressed)
		dialog.confirmed.connect(func():Global.start_download(url[1],'update'))
		dialog.dialog_text = "获取到了最新版本【v"+text_content.split("\n")[0]+"】是否更新？\n立即更新的更新过程会在控制台输出，请勿关闭引擎。"
		dialog.title = "检测到新版本"
		add_child(dialog)
		dialog.popup_centered()
		
func _on_custom_button_pressed():
	OS.shell_open(url[2])

func _on_show_pressed() -> void:
	if file_manager_pc.visible:
		file_manager_pc.hide()
		mb_window.get_popup().set_item_text(0,"显示文件管理器")
	else:
		file_manager_pc.show()

func _on_quit():
	if Global.currently_file_path == null:
		$ConfirmationDialog.show()
		return 
	if check_file_save(Global.currently_file_path):
		get_tree().quit()
	else:
		$ConfirmationDialog.show()

##提示对话框-确认
func _on_confirmation_dialog_confirmed() -> void:
	get_tree().quit()

func reflash_ui():
	if typeof(Global.get_uisettings_config("console_font_size")) != TYPE_STRING:
		console.add_theme_font_size_override("normal_font_size",Global.get_uisettings_config("console_font_size"))

func _add_output(content:String,mode:int=0):
	if mode == 0:
		console.append_text("\n"+content)
	elif mode == 1:
		reflash_ui()
		console.append_text("\n"+content)
	elif mode == 2:
		console.append_text(content)

func _add_progress_output(content: String):
	console.remove_paragraph(-1)
	# 更新文本
	console.append_text("\n"+content)
