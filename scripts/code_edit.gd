extends CodeEdit

# 自定义代码补全函数
func _request_code_completion(force: bool) -> void:
	# 获取当前光标位置
	var caret_line = get_caret_line()
	var caret_column = get_caret_column()
	
	# 获取当前行文本
	var line_text = get_line(caret_line)
	
	# 获取光标前的文本作为前缀
	var prefix = "" #作为存储光标前的文本的变量
	if caret_column > 0: #如果光标不位于行首
		prefix = line_text.substr(0, caret_column)
		
	## === 1.抽取“最近单词”作为过滤键 ===
	# 支持空格、tab、括号、运算符等任意分隔符
	var match := RegEx.create_from_string("[\\w\\u4e00-\\u9fff]+$").search(prefix)
	var key   = "" if match == null else match.get_string()
	var line   = get_line(get_caret_line())
	var col    = get_caret_column()
	# 如果光标不位于行首并且光标前的字符是.
	if col > 0 and line[col - 1] == '.':
		key = '.' + key
	
	# 检查是否在字符串或注释中
	if _is_in_string_or_comment(caret_line, caret_column):
		return
		
	## === 2.拼音首字母匹配（大小写不敏感） ===
	var low_key = key.to_lower()

	## 2.1 拼音 到 中文关键字
	for py in Global.pinyin_map:
		if py.begins_with(low_key) or Global.pinyin_map[py].begins_with(key):
			add_code_completion_option(
				CodeEdit.KIND_PLAIN_TEXT,
				Global.pinyin_map[py] + " (" + py + ")",
				Global.pinyin_map[py])

	## 2.2 中文函数
	for fn in Global.a_functions:
		var fn_py = Global.pinyin_map.get(fn, "")
		if fn_py.begins_with(low_key) or fn.begins_with(key):
			add_code_completion_option(
				CodeEdit.KIND_FUNCTION,
				fn + "() (" + fn_py + ")",
				fn + "()")
	
	# 添加控制结构补全
	if prefix.begins_with("如果") or prefix.begins_with("ruguo") or prefix.begins_with("rg"):
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, "如果 条件 那么", "如果  那么\n\t")
	
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
	code_completion_prefixes = PackedStringArray([])



func _on_text_changed() -> void:
	request_code_completion()
