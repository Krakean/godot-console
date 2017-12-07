# Godot Console
# ------------------------
# Contains test cases for Console
#
# ------------------------
# Author : Dmitry "Vortex" Koteroff
# Email  : krakean@outlook.com
# Date   : 05.12.2017 

extends Node

# Actual variables that keep current value.
var _cl_str     = "qwe"
var _cl_int     = 1
var _cl_float   = 1.234
var _cl_bool    = true
var _cl_intav   = 3
var _cl_floatav = 2.43
var _cl_strav   = "defbla"
var _cl_wrongCvar3  = "bla"
var _cl_wrongCvar4  = 9
var _cl_wrongCvar5  = 10
var _cl_wrongCvar6  = 20

# Get-set properties
var cl_str setget set_cl_str, get_cl_str
var cl_int setget set_cl_int, get_cl_int
var cl_float setget set_cl_float, get_cl_float
var cl_bool setget set_cl_bool, get_cl_bool
var cl_intav setget set_cl_intav, get_cl_intav
var cl_floatav setget set_cl_floatav, get_cl_floatav
var cl_strav setget set_cl_strav, get_cl_strav
var cl_wrongCvar3 setget set_cl_wrongCvar3, get_cl_wrongCvar3
var cl_wrongCvar4 setget set_cl_wrongCvar4, get_cl_wrongCvar4
var cl_wrongCvar5 setget set_cl_wrongCvar5, get_cl_wrongCvar5
var cl_wrongCvar6 setget set_cl_wrongCvar6, get_cl_wrongCvar6

func testfunc():
  Console.message("Hello123")

func testfunc2(integer):
  Console.message("Int: " + str(integer))

func testfunc3(intVar, strVar):
  Console.message("Int: " + str(intVar) + ", Str: " + str(strVar))

func testfunc4(intVar, strVar, fVar, bVar):
  Console.message("Int: " + str(intVar) + ", Str: " + str(strVar) + ", Float: " + str(fVar) + ", bool: " + str(bVar))

func set_cl_str(value):
	Console.message("Set str: " + str(value))
	_cl_str = value
	
func get_cl_str():
	return _cl_str	
	
func set_cl_int(value):
	Console.message("Set int: " + str(value))
	_cl_int = value
	
func get_cl_int():
	return _cl_int
	
func set_cl_float(value):
	Console.message("Set float: " + str(value))
	_cl_float = value
	
func get_cl_float():
	return _cl_float
	
func set_cl_bool(value):
	Console.message("Set bool: " + str(value))
	_cl_bool = value
	
func get_cl_bool():
	return _cl_bool	
	
func set_cl_intav(value):
	Console.message("Set AV int: " + str(value))
	_cl_intav = value
	
func get_cl_intav():
	return _cl_intav	
	
func set_cl_floatav(value):
	Console.message("Set AV float: " + str(value))
	_cl_floatav = value
	
func get_cl_floatav():
	return _cl_floatav
	
func set_cl_strav(value):
	Console.message("Set AV str: " + str(value))
	_cl_strav = value
	
func get_cl_strav():
	return _cl_strav
	
func set_cl_wrongCvar3(value):
	pass
	
func get_cl_wrongCvar3():
	return _cl_wrongCvar3	
	
func set_cl_wrongCvar4(value):
	pass

func get_cl_wrongCvar4():
	return _cl_wrongCvar4
	
func set_cl_wrongCvar5(value):
	pass

func get_cl_wrongCvar5():
	return _cl_wrongCvar5
	
func set_cl_wrongCvar6(value):
	pass

func get_cl_wrongCvar6():
	return _cl_wrongCvar6	

func _ready():
	Console.register_command("testfunc", {
		# used when printing help for a command.
		desc = "test func 0 args",
		# first one - actual count of arguments (used by parser), second one - used when printing help for a command, so you can write here anything - arguments name or type or some hints...
		args = [0, ""],
		# Target script to bind a corresponding function call
		target = self
  	})

	Console.register_command("testfunc2", {
		desc = "test func 1 args",
		args = [1, "<integer>"],
		target = self
  	})
	
	Console.register_command("testfunc3", {
		desc = "test func 2 args",
		args = [2, "<integer> <string>"],
		target = self
  	})	
	
	Console.register_command("testfunc4", {
		desc = "test func 4 args",
		args = [4, "<integer> <string> <float> <bool>"],
		target = self
  	})		
	
	Console.register_command("testfuncWRONG", {
		desc = "bad func (no func in target script)",
		args = [0, ""],
		target = self
	})
	
	Console.register_command("testfuncWRONG2", {
		desc = "bad func (wrong args -- no target & args)",
	})	
	
	Console.register_cvar("cl_wrongCvar1", {
		desc = "bad cvar (wrong args -- no target, desc, minmaxvals or defvals)",
		type = TYPE_INT
	})		
	
	Console.register_cvar("cl_wrongCvar2", {
		desc = "bad cvar (no getter/setter func in target script)",
		type = TYPE_INT,
		minmax_values = [0, 10],
		target = self,
	})			
	
	Console.register_cvar("cl_wrongCvar3", {
		desc = "bad cvar (no min max OR allowed vals for int)",
		type = TYPE_INT,
		target = self,
	})			
	
	Console.register_cvar("cl_wrongCvar4", {
		desc = "bad cvar (def value and allowed vals mismatch)",
		type = TYPE_INT,
		allowed_values = [0, 1, 2],
		target = self,
	})				
	
	Console.register_cvar("cl_wrongCvar5", {
		desc = "bad cvar (def value and minmax vals mismatch)",
		type = TYPE_INT,
		minmax_values = [0, 5],
		target = self,
	})					
	
	Console.register_cvar("cl_wrongCvar6", {
		desc = "bad cvar (only either allowed values or minmax values is allowed for ints/floats)",
		type = TYPE_INT,
		minmax_values = [0, 5],
		allowed_values = [10, 20],
		target = self,
	})						
	
	Console.register_cvar("cl_wrongCvar7", {
		desc = "bad cvar (unsupported type)",
		type = TYPE_NODE_PATH,
		target = self,
	})	

	Console.register_cvar("cl_int", {
		# cvar desc in an arbitrary form
		desc = "var INT desc",
		# TYPE_INT or TYPE_STRING or TYPE_REAL or TYPE_BOOL only allowed
		type = TYPE_INT,
		# Minimal and maximal value that this cvar can have.
		minmax_values = [-10, 5],
		# OR (can't have both - minmax & allowed) cvar can have only particular values? 
		allowed_values = [],
		# Should always be "self"
		target = self
	})	
	
	Console.register_cvar("cl_str", {
		desc = "var STR desc",
		type = TYPE_STRING,
		allowed_values = [],
		target = self
	})	  

	Console.register_cvar("cl_float", {
		desc = "var FLOAT desc",
		type = TYPE_REAL,
		minmax_values = [-2.0, 32.6],
		allowed_values = [],
		target = self
	})
	
	Console.register_cvar("cl_bool", {
		desc = "var BOOL desc",
		type = TYPE_BOOL,
		target = self
	})	
	
	Console.register_cvar("cl_intav", {
		desc = "var INT desc with ALLOWED VALUES",
		type = TYPE_INT,
		allowed_values = [-2, 1, 3, 5],
		target = self
	})		
	
	Console.register_cvar("cl_floatav", {
		desc = "var Float desc with ALLOWED VALUES",
		type = TYPE_REAL,
		allowed_values = [-0.7, 0.50, 1.0, 1.5, 2.43],
		target = self
	})			
	
	Console.register_cvar("cl_strav", {
		desc = "var STR desc with ALLOWED VALUES",
		type = TYPE_STRING,
		allowed_values = ["defval", "defbla", "yobla"],
		target = self
	})
	
	Console.Log("Simple log message")
	Console.LogWarn("Warning log message")
	Console.LogErr("Error log message")