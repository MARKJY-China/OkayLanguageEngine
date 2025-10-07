extends Control


func _on_back_pressed() -> void:
	hide()


func _on_build_pressed() -> void:
	var code = Global.compile_code($"../IDE-Center/Margin/Code/Work/CodeEdit".text)
	var code_temp_file = "C:/okay_language_engine/temp_python_builder.py"
	var code_file = FileAccess.open(code_temp_file, FileAccess.WRITE)
	code_file.store_string(code)
	code_file.close()
	var python_code = "python pyinstaller --onefile --clean "+code_temp_file.get_file()
	var temp_file = "C:/okay_language_engine/builder.py"
	var file = FileAccess.open(temp_file, FileAccess.WRITE)
	file.store_string(python_code)
	file.close()
	# 检查Python路径是否有效
	if not FileAccess.file_exists(Global.currently_python_interpreter):
		Global.send_output.emit(Global.get_hint_text('Error')+"错误: Python解释器未找到: " + Global.currently_python_interpreter)
		return
	
	# 执行Python脚本
	var output = []
	
	#var exit_code = OS.execute(Global.currently_python_interpreter, [ProjectSettings.globalize_path(temp_file)], output)
	var exit_code = OS.execute("CMD.exe", ["/C", python_code], output)
	
	
	# 显示输出结果
	if exit_code == 0:
		print("执行成功:")
		Global.send_output.emit(Global.get_hint_text('')+"代码运行成功>")
		for line in output:
			print(line)
			Global.send_output.emit(line)
	else:
		print("执行失败，错误代码: ", exit_code)
		Global.send_output.emit(Global.get_hint_text('Error')+"执行失败，错误代码: "+str(exit_code)+"|Python解释器路径："+Global.python_path)
		for line in output:
			Global.send_output.emit(line)
			print(line)
