# Godot Console
# ------------------------
# Implements game console.
#
# ------------------------
# Author : Dmitry "Vortex" Koteroff
# Email  : krakean@outlook.com
# Date   : 27.11.2017

extends CanvasLayer

onready var console_box      = $ConsoleBox
onready var console_text     = $ConsoleBox/Container/ConsoleControl/ConsoleText
onready var console_line     = $ConsoleBox/Container/LineEdit
onready var animation_player = $ConsoleBox/AnimationPlayer

# Those are the scripts containing command and cvar code
var cmd_history          = []
var cmd_history_count    = 0
var cmd_history_up       = 0

# For tabbing commands
var prev_com               = ""
var entered_latters        = ""
var prev_entered_latters   = ""
var text_changed_by_player = true # text_changed_by_player needs for not changing other vals by signal "text_changed"
var found_commands_list    = []
var is_tab_pressed         = false

# All recognized commands
var commands = {}

# All recognized cvars
var cvars    = {}

# Used for variable type detection
var builtin_type_names = ["nil", "bool", "int", "float", "string", "vector2", "rect2", "vector3", "maxtrix32", "plane", "quat", "aabb",  "matrix3", "transform", "color", "image", "nodepath", "rid", null, "inputevent", "dictionary", "array", "rawarray", "intarray", "realarray", "stringarray", "vector2array", "vector3array", "colorarray", "unknown"]

# Used in Log***
const COLOR_LOG_WARNING        = "#FFD56F"
const COLOR_LOG_ERROR          = "#E84D58"
# Used in messageColoredErr and in handle_command
const COLOR_MSG_ERR            = "#E84D58"
const COLOR_MSG_ERR_VAR_NAME   = "#EA92DC"
# Used in messageColoredCmdDesc
const COLOR_MSG_CMD_DESC       = "#FFD56F"
const COLOR_MSG_CMD_DESC_USAGE = "#5CCBE3"
# Used in describe_cvars
const COLOR_MSG_CVAR_DESC_CVAR   = "#9ABC65"
const COLOR_MSG_CVAR_DESC_VALUE  = "#9999ff"
const COLOR_MSG_CVAR_DESC_DEFVAL = "#EA92DC"
const COLOR_MSG_CVAR_DESC_ALLVAL = "#ffaefa"

# BUILT-IN CONSOLE COMMANDS START #

# Lists all available commands
func cmdlist():
	var commands = Console.commands
	for command in commands:
		describe_command(command)

# Enumerate history content and return it.
func history():
	var strOut = ""
	var count  = 0
	for i in range(0, cmd_history.size()-1):
		if (i == cmd_history.size()-2):
			strOut += "[color=#ffff66]" + str(count+1) + ".[/color] " + cmd_history[i]
		else:
			strOut += "[color=#ffff66]" + str(count+1) + ".[/color] " + cmd_history[i] + "\n"
		count+=1
	
	message(strOut)

# Lists all available cvars
func cvarlist():
	var cvars = Console.cvars
	for cvar in cvars:
		describe_cvar(cvar)

# Clear the console window
func clear():
	console_text.set_bbcode("")	

# Exits the application
func quit():
	get_tree().quit()
	
# BUILT-IN CONSOLE COMMANDS END #

# Console initialization.	
func _ready():
	# Allow selecting console text
	console_text.set_selection_enabled(true)
	# Follow console output (for scrolling)
	console_text.set_scroll_follow(true)
	
	# Transparency settings
	console_box.self_modulate  = Color(1, 1, 1, 0.87) # whole console transparency (container + consoletext + consoleline)
	console_line.self_modulate = Color(1, 1, 1, 1)    # transparency for console line
	
	animation_player.connect("animation_finished", self, "_on_AnimationPlayer_finished")
	console_line.connect("text_entered", self, "_on_LineEdit_text_entered")
	console_line.connect("text_changed", self, "_on_LineEdit_text_changed")
	
	animation_player.set_current_animation("fade")
	# Hide console on start
	set_console_opened(true)
	console_box.hide()
	
	# By default we show quick help
	var version     = Engine.get_version_info()
	var placeholder = "%s v1.0 (using Godot v%s.%s.%s.%s-%s)\nType [color=#FFD56F]cmdlist[/color] to get a list of all available commands\n[color=#9ABC65]===========[/color]"
	var outstr      = placeholder % [ProjectSettings.get_setting("application/config/name"), str(version.major), str(version.minor), str(version.patch), version.status, version.build]
	message(outstr)

	# Register built-in commands
		
	register_command("cmdlist", {
		# used when printing help for a command.
		desc        = "Lists all available commands",
		# first one - actual count of arguments (used by parser), second one - used when printing help for a command, so you can write here anything - arguments name or type or some hints...
		args        = [0, ""],
		# Target script to bind a corresponding function call
		target      = self
	})	
	
	register_command("cvarlist", {
		desc        = "Lists all available cvars",
		args        = [0, ""],
		target      = self
	})	
	
	register_command("quit", {
		desc        = "Exits the application",
		args        = [0, ""],
		target      = self
	})

	register_command("clear", {
		desc        = "Clear the console window",
		args        = [0, ""],
		target      = self
	})	
	
	register_command("history", {
		desc        = "Print all previous cmd used during the session",
		args        = [0, ""],
		target      = self
	})
	
	set_process_input(true)	
	
# Process keyboard input.
func _input(event):	
	# Show/hide console.
	if Input.is_action_just_pressed("console_toggle"):
		# Remove the "~" from line edit on console appear.
		console_line.accept_event()

		var opened = is_console_opened()
		if opened == 1:
			set_console_opened(false)
		elif opened == 0:
			set_console_opened(true)
			
	# Console input history up (oldest)
	elif Input.is_action_just_pressed("console_up"):
		if (cmd_history_up > 0 and cmd_history_up <= cmd_history.size()):
			cmd_history_up -= 1
			set_linetext(cmd_history[cmd_history_up])
			
	# Console input history down (recent)
	elif Input.is_action_just_pressed("console_down"):
		if (cmd_history_up > -1 and cmd_history_up + 1 < cmd_history.size()):
			cmd_history_up += 1
			set_linetext(cmd_history[cmd_history_up])
		elif (cmd_history_up > -1 and cmd_history_up + 1 == cmd_history.size()):
			cmd_history_up +=1
			set_linetext(entered_latters)
		# no more recent, hide last recent and show empty console input line.
		else:
			cmd_history_up = cmd_history.size(); # allows easily go back to most recent by pressing Key Up.
			console_line.set_text("")
			console_line.grab_focus()
			
	# Console scroll up
	elif Input.is_action_just_pressed("console_scroll_up"):
		var vscrl = console_text.get_v_scroll();
		var linesbackward = vscrl.get_value() - vscrl.get_page() * 0.5 / 1
		vscrl.set_value(linesbackward)
		
	# Console scroll down
	elif Input.is_action_just_pressed("console_scroll_down"):
		var vscrl = console_text.get_v_scroll();
		var linesforward = vscrl.get_value() + vscrl.get_page() * 0.5 / 1
		vscrl.set_value(linesforward)
		
	# Scroll to beginning of Console quickly
	elif Input.is_action_pressed("console_scroll_to_begin"):
		console_text.scroll_to_line(0)
	
	# Scroll to end of Console quickly
	elif Input.is_action_pressed("console_scroll_to_end"):
		console_text.scroll_to_line(console_text.get_line_count()-1)

	# Handle auto-completion by Tab-key.
	if is_tab_pressed:
		is_tab_pressed = Input.is_key_pressed(KEY_TAB)
	if console_line.get_text() != "" and console_line.has_focus() and Input.is_key_pressed(KEY_TAB) and not is_tab_pressed:	
		complete()
		is_tab_pressed = true
		
	# Transfer focus to console line edit when any key pressed on console text when its focused
	if event.is_pressed() and not Input.is_key_pressed(KEY_CONTROL) and not Input.is_key_pressed(KEY_ALT) and not Input.is_key_pressed(KEY_SHIFT) and console_text.has_focus():
		console_line.grab_focus()
			
# This signal handles the hiding of the console at the end of the fade-out animation
func _on_AnimationPlayer_finished(anim):
	if is_console_opened():
		console_box.hide()
		
# Called when the user presses Enter in the console
func _on_LineEdit_text_entered(text):
	# used to manage cmd history
	if cmd_history.size() > 0:
		if (text != cmd_history[cmd_history_count - 1]):
			cmd_history.append(text)
			cmd_history_count+=1
	else:
		cmd_history.append(text)
		cmd_history_count+=1
	cmd_history_up = cmd_history_count
	var text_splitted = text.split(" ", true)
	# Don't do anything if the LineEdit contains only spaces
	if not text.empty() and text_splitted[0]:
		handle_command(text)
		
		# Clear input field and scroll to console end
		console_line.clear()
		console_text.scroll_to_line(console_text.get_line_count()-1)		
	else:
		# Clear the LineEdit but do nothing
		console_line.clear()
		
# Called when user change text
func _on_LineEdit_text_changed(text):
	if text_changed_by_player:
		entered_latters = text
		
# Is the console fully opened?
func is_console_opened():
	if animation_player.get_current_animation() != "":
		if animation_player.get_current_animation_position() == animation_player.get_current_animation_length():
			return 1
		elif animation_player.get_current_animation_position() == 0:
			return 0
		else:
			return 2
	return 0
	
# Open or close console.
func set_console_opened(opened):
	# Close the console
	if opened == true:
		animation_player.play("fade")
		# Signal handles the hiding at the end of the animation
		console_box.hide()
		console_line.clear()
	# Open the console
	elif opened == false:
		animation_player.play_backwards("fade")
		console_box.show()
		console_line.grab_focus()
		console_line.clear()
		
# Convert allowed values from dictionary to comma-separated string		
func AllowedValuesToStr(allowed_values):
	var av = "any"
	if (allowed_values.size() > 0):
		av = str(allowed_values[0])
		for idx in range(1, allowed_values.size()):
			av = av + ", " + str(allowed_values[idx])
			
	return av
	
# Convert milliseconds to hours/minutes/seconds/ms
func MakeTimeUsingMS(ms):
	var time = { hours = 0, minutes = 0, seconds = 0, msec = 0 }
	
	time.seconds   = (ms / 1000) % 60
	time.minutes   = ((ms / (1000 * 60)) % 60)
	time.hours     = ((ms / (1000 * 60 * 60)) % 24)
	time.msec      = ms
		
	return time	
	
# Used to ensure that given value for console variable is correct
const _patterns = {
	# bool
	'1': '^(1|0|true|false|TRUE|FALSE|True|False)$',  
	# int
	'2': '^[+-]?([0-9]*)?$',  
	# float
	'3': '^[+-]?([0-9]*[\\.\\,]?[0-9]+|[0-9]+[\\.\\,]?[0-9]*)([eE][+-]?[0-9]+)?$'
}
# Used as cache	
var _compiled = {}

# Ensure that value is correct
func check_value_by_type(variable_type):
	var str_type  = variable_type	
	if (str_type > 3):
		return FAILED

	if !_compiled.has(str_type):
		var r = RegEx.new()
		r.compile(_patterns[str(str_type)])

		if r and r is RegEx:
			_compiled[str_type] = r
		else:
			return FAILED

	return _compiled[str_type] 	

func value_within_allowed(val, allowed_values):	
	for i in range(0, allowed_values.size()):
		if str(allowed_values[i]) == str(val):
			return true
			
	return false	
	
# Set console line text	
func set_linetext(string):
	text_changed_by_player = false
	console_line.set_text(string)
	text_changed_by_player = true

	console_line.set_cursor_position(console_line.text.length() + 1)
	console_line.grab_focus()		
	
# Command/cvar completion (by Tab, for example)
func complete():
	var text       = entered_latters
	var last_match = ""
	
	if prev_entered_latters != entered_latters or found_commands_list.empty():
		found_commands_list = []
		# If there are no matches found yet, try to complete for a command or cvar
		for command in commands:
			if command.begins_with(text):
				# We have first match, so show friendly message to console to make auto-compl a bit viewable-friendly
				if (found_commands_list.size() == 0):
					message("\nAuto-completion matches for Commands:")
				
				describe_command(command)
				last_match = command
				found_commands_list.append(command)
		var firsttime = true
		for cvar in cvars:
			if cvar.begins_with(text):
				# We have first match, so show friendly message to console to make auto-compl a bit viewable-friendly
				if (found_commands_list.size() == 0 or firsttime):
					message("\nAuto-completion matches for CVars:")
					firsttime = false
				
				describe_cvar(cvar)
				last_match = cvar
				found_commands_list.append(cvar)
	
	if found_commands_list.size() > 0 and prev_com == "":
		prev_com = found_commands_list[0]
	var idx = found_commands_list.find(prev_com)
	
	if idx != -1:
		set_linetext(found_commands_list[idx] + " ")
		if ((idx+1) < found_commands_list.size()):
			prev_com = found_commands_list[idx+1]
		else:
			prev_com = found_commands_list[0]
	else:
		prev_com = last_match
		if !prev_com.empty():
			set_linetext(prev_com + " ")
	
	prev_entered_latters = entered_latters
		
# Prints message to console
func message(bbcode, print_time = false):
	var time = "";
	if (print_time == true):
		var ms = OS.get_ticks_msec()
		var t = MakeTimeUsingMS(ms)
		var placeholder = "[%02d:%02d:%02d] "
		time = placeholder % [t.hours, t.minutes, t.seconds]
	console_text.set_bbcode(console_text.get_bbcode() + time + bbcode + "\n")
		
# Colorized error message, like: cannot register ... param name ... (error desc)
func messageColoredErr(msg_error_general, msg_error_param = "", msg_error_desc = ""):	
	if (msg_error_param == "" and msg_error_desc == ""):
		message("[i][color=" + COLOR_MSG_ERR + "]" + msg_error_general + "[/color][/i]")
	elif (msg_error_desc == ""):
		message("[i][color=" + COLOR_MSG_ERR + "]" + msg_error_general + "[/color][/i] [u][color=" + COLOR_MSG_ERR_VAR_NAME + "]" + msg_error_param + "[/color][/u]")
	else:
		message("[i][color=" + COLOR_MSG_ERR + "]" + msg_error_general + "[/color][/i] [u][color=" + COLOR_MSG_ERR_VAR_NAME + "]" + msg_error_param + "[/color][/u] (" + msg_error_desc + ")")
	
# Colorized console cmd description
func messageColoredCmdDesc(msg_cmd, msg_cmd_desc, msg_cmd_desc_usage):
	message("[color=" + COLOR_MSG_CMD_DESC + "]" + msg_cmd + ":[/color] " + msg_cmd_desc + " (usage: [color=" + COLOR_MSG_CMD_DESC_USAGE + "]" + msg_cmd_desc_usage + "[/color])")	
	
func Log(bbcode):
	message(bbcode, true)
	
func LogWarn(bbcode):
	message("[color=" + COLOR_LOG_WARNING + "]" + bbcode + "[/color]", true)
	
func LogErr(bbcode):
	message("[color=" + COLOR_LOG_ERROR + "]" + bbcode + "[/color]", true)
		
# Registers a new console command
func register_command(name, args):
	if args.has("target") and args.target != null and args.has("desc") and args.has("args"):
		if args.target.has_method(name):
 			commands[name] = args
		else:
			messageColoredErr("Cannot register command:", name, "the target script has no corresponding function")
	else:
		messageColoredErr("Cannot register command:", name, "wrong arguments")

# Registers a new cvar (console variable)
func register_cvar(name, args):	
	if args.has("target") and args.target != null and args.has("desc") and args.has("type"):
		if (args.type != TYPE_STRING and args.type != TYPE_INT and args.type != TYPE_REAL and args.type != TYPE_BOOL):
			messageColoredErr("Cannot register cvar:", name, "wrong cvar type: [u]" + builtin_type_names[args.type] + "[/u], expected: int, float, string or boolean")
			return
		
		var hasMMVals = args.has("minmax_values") and args.minmax_values.size() > 0
		var hasALVals = args.has("allowed_values") and args.allowed_values.size() > 0
		if args.type == TYPE_INT or args.type == TYPE_REAL:
			if (not hasMMVals and not hasALVals) or (hasMMVals and hasALVals):
				messageColoredErr("Cannot register cvar:", name, "the integer/float parameters should have either minmax_values or allowed_values argument, nor none nor both")
				return

		var firstvalue = args.target.get(name)
		if firstvalue != null:
			# Check whether default value is within allowed/minmax values range, if not then enforce a programmer to fix this possible issue.
			if (hasALVals):
				if not value_within_allowed(firstvalue, args.allowed_values):					
					messageColoredErr("Cannot register cvar:", name, "default value and allowed values mismatch")
					return
			elif (hasMMVals):
				if (firstvalue < args.minmax_values[0] or firstvalue > args.minmax_values[1]):
					messageColoredErr("Cannot register cvar:", name, "default value and minmax values mismatch")
					return					
			
			args.default_value = firstvalue
			cvars[name] = args
		else:
			messageColoredErr("Cannot register cvar:", name, "the target script has no getter and/or setter function")
	else:
		messageColoredErr("Cannot register command:", name, "wrong arguments")

# Describes a command, used by the "cmdlist" command and when the user enters a command name without any arguments (if it requires at least 1 argument)
func describe_command(cmd):
	var command     = commands[cmd]
	var description = command.desc
	var args        = command.args
	
	if args[0] >= 1:
		messageColoredCmdDesc(cmd, description, cmd + " " + args[1])
	else:
		messageColoredCmdDesc(cmd, description, cmd)

# Describes a cvar, used by the "cvarlist" command and when the user enters a cvar name without any arguments
func describe_cvar(cvar):
	var cvariable      = cvars[cvar]
	var description    = cvariable.desc
	var type           = cvariable.type
	var default_value  = cvariable.default_value
	var value          = cvariable.target.get(cvar)
	var allowed_values = []
	if cvariable.has("allowed_values"):
		allowed_values = cvariable.allowed_values

	# Gather allowed values.	
	var av = AllowedValuesToStr(allowed_values)
			
	# Setup output string template + colors
	var colors_scheme = {
		"CVAR"   : COLOR_MSG_CVAR_DESC_CVAR,
		"VALUE"  : COLOR_MSG_CVAR_DESC_VALUE,
		"DEFVAL" : COLOR_MSG_CVAR_DESC_DEFVAL,
		"ALLVAL" : COLOR_MSG_CVAR_DESC_ALLVAL,
	}

	var placeholder = "[color=%s]%s:[/color] [color=%s]%s[/color] %s ([u]%s[/u], [i]default:[/i] [color=%s]%s[/color], [i]allowed values:[/i] [color=%s]%s[/color])"
	var outstr = ""
	
	# Now, depending on type, show proper cvar description.
	if (type == TYPE_STRING || type == TYPE_BOOL):
		if (type == TYPE_BOOL):
			av = "true..false"
			outstr = placeholder % [colors_scheme["CVAR"], str(cvar), colors_scheme["VALUE"], str(value).to_lower(), str(description), builtin_type_names[type], colors_scheme["DEFVAL"], str(default_value).to_lower(), colors_scheme["ALLVAL"], str(av)]
		else:
			outstr = placeholder % [colors_scheme["CVAR"], str(cvar), colors_scheme["VALUE"], str(value), str(description), builtin_type_names[type], colors_scheme["DEFVAL"], str(default_value), colors_scheme["ALLVAL"], str(av)]
	elif (type == TYPE_INT || type == TYPE_REAL):
		if (av != "any"):
			outstr = placeholder % [colors_scheme["CVAR"], str(cvar), colors_scheme["VALUE"], str(value), str(description), builtin_type_names[type], colors_scheme["DEFVAL"], str(default_value), colors_scheme["ALLVAL"], str(av)]
		else:
			av = str(cvariable.minmax_values[0]) + ".." + str(cvariable.minmax_values[1])
			outstr = placeholder % [colors_scheme["CVAR"], str(cvar), colors_scheme["VALUE"], str(value), str(description), builtin_type_names[type], colors_scheme["DEFVAL"], str(default_value), colors_scheme["ALLVAL"], str(av)]			
	
	# Output formatted string to console.
	message(outstr)

# Process the console command.
func handle_command(text):
	# The current console text, splitted by spaces (for arguments)
	var cmd = text.split(" ", true)
	message("[b]> " + text + "[/b]")
	
	# Remove empty args that produced by split in case when empty space between [ccom/cvar] and [arg]
	var cmd_clean = []
	var cmd_temp  = range(cmd.size())
	if cmd.size() > 1:
		for i in range(cmd.size()):
			if not cmd[i].empty():
				cmd_clean.append(cmd[cmd_temp[i]])
				
		cmd = cmd_clean

	# Check if the first word is a valid command
	if commands.has(cmd[0]):
		var command = commands[cmd[0]]

		# If no argument is supplied, then show command description and usage, but only if command has at least 1 argument required
		if cmd.size() == 1 and not command.args[0] == 0:
			describe_command(cmd[0])
		else:
			if command.args[0] == 0: # If there are no arguments, don't pass any to the other script.
				command.target.call(cmd[0].replace(".", ""))
			else:
				var args = []
				# Major flaw of this approach: no type checking for given command arguments
				for i in range(1, cmd.size()):
					args.append(cmd[i])
					
				if args.size() != int(command.args[0]):
					messageColoredErr("Console command got incorrect amount of arguments:", str(args.size()), "expected: " + str(command.args[0]))
				else:
					command.target.callv(cmd[0].replace(".", ""), args)
				
	# Check if the first word is a valid cvar
	elif cvars.has(cmd[0]):
		var cvar = cvars[cmd[0]]
		
		# If no argument is supplied, then show cvar description and usage
		if cmd.size() == 1:
			describe_cvar(cmd[0])
		else:
			var value_passed     = false
			var bad_allowed_vals = false
			var bad_minmax_vals  = false
			var baserematch      = null
			var rematch          = null
			# We do not support regex for strings since they can contain anything
			if (cvar.type != TYPE_STRING):
				baserematch      = check_value_by_type(cvar.type)
				rematch          = baserematch.search(cmd[1])
			var val              = ""
			
			# String cvar
			if cvar.type == TYPE_STRING:
				val = str(cmd[1])
			
				# Check whether given value is contains at least one of allowed_values.
				if cvar.has("allowed_values") and cvar.allowed_values.size() > 0:					
					bad_allowed_vals = true
					if value_within_allowed(val, cvar.allowed_values):
						value_passed     = true
						bad_allowed_vals = false
				else:
					value_passed = true
				
				if value_passed:
					for word in range(1, cmd.size()):
						if word == 1:
							cvar.value = str(cmd[word])
						else:
							cvar.value += str(" " + cmd[word])
					
			# Integer cvar
			elif cvar.type == TYPE_INT:
				if not rematch or !(rematch is RegExMatch):
					messageColoredErr("CVar got value of incorrect type while expecting [u]integer[/u]")
					return
					
				val = int(rematch.get_string())
				
				# If no allowed_values given, make sure given value is within min/max value range
				if not cvar.has("allowed_values") or cvar.allowed_values.size() == 0:									
					# Is it within range?
					if (val < int(cvar.minmax_values[0]) or val > int(cvar.minmax_values[1])):
						bad_minmax_vals = true
					else:
						value_passed    = true
						
					if value_passed:
						cvar.value = clamp(val, int(cvar.minmax_values[0]), int(cvar.minmax_values[1]))
				else:					
					# Check whether given value is contains at least one of allowed_values.
					bad_allowed_vals = true
					if value_within_allowed(val, cvar.allowed_values):
						value_passed     = true
						bad_allowed_vals = false
							
					if value_passed:
						cvar.value = val
						
			# Float cvar
			elif cvar.type == TYPE_REAL:
				if not rematch or !(rematch is RegExMatch):
					messageColoredErr("CVar got value of incorrect type while expecting [u]float[/u]")
					return
					
				# Fix case when we receive float like 0,5 not 0.5
				val = float(rematch.get_string().replace(',', '.'))
				
				# If no allowed_values given, make sure given value is within min/max value range
				if not cvar.has("allowed_values") or cvar.allowed_values.size() == 0:					
					# Is it within range?
					if (val < float(cvar.minmax_values[0]) or val > float(cvar.minmax_values[1])):
						bad_minmax_vals = true
					else:
						value_passed = true
						cvar.value   = clamp(val, float(cvar.minmax_values[0]), float(cvar.minmax_values[1]))						
				else:
					# Check whether given value is contains at least one of allowed_values.
					bad_allowed_vals = true
					if value_within_allowed(val, cvar.allowed_values):
						value_passed     = true
						bad_allowed_vals = false
						
					# Everything is fine.
					if value_passed:
						cvar.value = val
									
			# Bool cvar
			elif cvar.type == TYPE_BOOL:
				if not rematch or !(rematch is RegExMatch):
					messageColoredErr("CVar got value of either [u]out of range[/u] or incorrect type while expecting [u]boolean[/u]")
					return
				
				value_passed = true
				if (rematch.get_strings()[0].to_lower() == "true" || rematch.get_strings()[0] == "1"):
					cvar.value = true
				else:
					cvar.value = false
					
			if not value_passed and bad_allowed_vals:
				messageColoredErr("CVar got value that is out of allowed values:", str(val), "excepted: " + AllowedValuesToStr(cvar.allowed_values))
			elif not value_passed and bad_minmax_vals:
				messageColoredErr("CVar got value that is out of range:", str(val), "excepted: " + str(cvar.minmax_values[0]) + ".." + str(cvar.minmax_values[1]))					

			# Call setter code
			if value_passed == true:
				cvar.target.set(cmd[0], cvar.value)
	else:
		messageColoredErr("Unknown command or cvar:", cmd[0])