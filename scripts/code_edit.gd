extends CodeEdit

# 自定义代码补全函数
func _request_code_completion(force: bool) -> void:
	# 获取当前光标位置
	var caret_line = get_caret_line()
	var caret_column = get_caret_column()
	
	# 获取当前行文本
	var line_text = get_line(caret_line)
	
	# 获取光标前的文本作为前缀
	var prefix = ""
	if caret_column > 0:
		prefix = line_text.substr(0, caret_column)
	
	# 检查是否在字符串或注释中
	if _is_in_string_or_comment(caret_line, caret_column):
		return
	
	# 添加拼音补全选项
	for pinyin in Global.pinyin_map:
		# 检查前缀是否匹配拼音
		if prefix.is_empty() or pinyin.begins_with(prefix):
			var keyword = Global.pinyin_map[pinyin]
			add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, keyword + " (" + pinyin + ")", keyword)
	
	# 添加中文关键字补全选项
	for keyword in Global.a_keywords:
		# 检查前缀是否匹配
		if prefix.is_empty() or keyword.begins_with(prefix):
			add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, keyword, keyword)
	
	# 添加常用函数补全
	var functions = [
		{"name": "主函数", "params": []},
		{"name": "循环", "params": ["次数"]},
		{"name": "输入", "params": ["提示"]},
		{"name": "随机数", "params": ["最小值", "最大值"]}
	]
	
	for func_data in functions:
		var func_name = func_data["name"]
		var func_pinyin = Global.function_pinyin.get(func_name, "")
		
		# 检查拼音匹配
		if !func_pinyin.is_empty() and (prefix.is_empty() or func_pinyin.begins_with(prefix)):
			var insert_text = func_name
			if func_data["params"].size() > 0:
				insert_text += "("
				for i in range(func_data["params"].size()):
					insert_text += "${%d:%s}" % [i+1, func_data["params"][i]]
					if i < func_data["params"].size() - 1:
						insert_text += ", "
				insert_text += ")"
			
			add_code_completion_option(CodeEdit.KIND_FUNCTION, 
				func_name + "() (" + func_pinyin + ")", insert_text)
		
		# 检查中文匹配
		if prefix.is_empty() or func_name.begins_with(prefix):
			var insert_text = func_name
			if func_data["params"].size() > 0:
				insert_text += "("
				for i in range(func_data["params"].size()):
					insert_text += "${%d:%s}" % [i+1, func_data["params"][i]]
					if i < func_data["params"].size() - 1:
						insert_text += ", "
				insert_text += ")"
			
			add_code_completion_option(CodeEdit.KIND_FUNCTION, 
				func_name + "()", insert_text)
	
	# 添加控制结构补全
	if prefix.begins_with("如果") or prefix.begins_with("ruguo") or prefix.begins_with("rg"):
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, "如果 条件 那么", "如果 1:条件 那么\n\t${2:代码}\n结束")
	
	# 更新补全选项
	update_code_completion_options(force)

# 检查是否在字符串或注释中
func _is_in_string_or_comment(line: int, column: int) -> bool:
	# 获取语法高亮器
	var highlighter = syntax_highlighter
	if not highlighter:
		return false
	
	# 获取当前行的高亮信息
	var highlighting = highlighter._get_line_syntax_highlighting(line)
	
	# 检查当前位置是否在字符串或注释中
	for start_index in highlighting:
		var info = highlighting[start_index]
		var end_index = start_index + info.length
		
		if column >= start_index and column <= end_index:
			if info.color == highlighter.string_color or info.color == highlighter.comment_color:
				return true
	
	return false

# 在ready函数中启用代码补全
func _ready() -> void:
	code_completion_enabled = true
	code_completion_prefixes = PackedStringArray([
		".",
		" "
	])



func _on_text_changed() -> void:
	request_code_completion()
