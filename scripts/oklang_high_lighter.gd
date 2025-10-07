extends SyntaxHighlighter

# ---------- 颜色 ----------
var keyword_color_a  := Color.BLUE_VIOLET
var keyword_color_b  := Color.CORAL
var keyword_color_c := Color.CHOCOLATE
var keyword_color_d := Color.BROWN
var keyword_color_e := Color.CHARTREUSE
var function_color_a := Color.CORNFLOWER_BLUE
var string_color   := Color.BURLYWOOD
var comment_color  := Color.DIM_GRAY
var number_color   := Color.AQUAMARINE
var symbol_color   := Color.LIGHT_BLUE

# 跨行字符串状态
var in_string_cache := {}
var digit_regex := RegEx.new()
var word_regex  := RegEx.new()   # 连续字母/数字/下划线/中文
var sym_regex   := RegEx.new()   # 单个非单词字符
var symb_regex   := RegEx.new()   # 单个非单词字符
var id_char_regex := RegEx.new()
var number_regex := RegEx.new()

func _init() -> void:
	digit_regex.compile("^[0-9]$")   # 只匹配一个数字字符
	word_regex.compile("^\\w$")        # \w 包含中文、字母、数字、下划线
	sym_regex.compile("^[^\\w\\s]$")    # 单个非单词、非空白字符
	id_char_regex.compile("^[A-Za-z\\p{Han}]$")   # \w + 任意汉字
	number_regex.compile("^\\d+$")      # 整串数字
	symb_regex.compile(r"[+=:,<>
 $$$$ {}()/\\$$ ]")

func _get_line_syntax_highlighting(line_index: int) -> Dictionary:
	var result := {}
	var line := get_text_edit().get_line(line_index)

	var i := 0
	var in_string := false
	if line_index > 0 and in_string_cache.has(line_index - 1):
		in_string = in_string_cache[line_index - 1]

	# 注释直接吞到行尾
	if not in_string:
		var comment_pos := line.find("#")
		if comment_pos != -1:
			result[comment_pos] = { color = comment_color, length = line.length() - comment_pos }
			return result   # 后面全被注释吃掉，直接返回

	while i < line.length():
		var c := line[i]

		# 字符串
		if c == '"':
			var start := i
			i += 1
			while i < line.length():
				if line[i] == '"' and line[i - 1] != '\\':
					i += 1
					in_string = false
					break
				i += 1
			result[start] = { color = string_color, length = i - start }
			continue

		# 3. 关键字
		if not in_string and id_char_regex.search(c):
			var start := i
			while i < line.length() and id_char_regex.search(line[i]):
				i += 1
			var word := line.substr(start, i - start)
			if (word in Global.a_keywords) or (word in Global.a_keywords_en):
				result[start] = { color = keyword_color_a, length = word.length() }
			elif (word in Global.b_keywords) or (word in Global.b_keywords_en):
				result[start] = { color = keyword_color_b, length = word.length() }
			elif (word in Global.c_keywords) or (word in Global.c_keywords_en):
				result[start] = { color = keyword_color_c, length = word.length() }
			elif (word in Global.d_keywords) or (word in Global.d_keywords_en):
				result[start] = { color = keyword_color_d, length = word.length() }
			elif (word in Global.e_keywords) or (word in Global.e_keywords_en):
				result[start] = { color = keyword_color_e, length = word.length() }
			elif (word in Global.a_functions) or (word in Global.a_functions_en):
				result[start] = { color = function_color_a, length = word.length() }
			continue

		# 4. 数字
		if not in_string and (number_regex.search(c) or digit_regex.search(c)):
			var start := i
			while i < line.length() and number_regex.search(line[i]):
				i += 1
			result[start] = { color = number_color, length = i - start }
			continue

		# 符号（单个字符）
		if not in_string and symb_regex.search(c):
			result[i] = { color = symbol_color, length = 1 }
			i += 1
			continue
		
		i += 1
	in_string_cache[line_index] = in_string
	return result
