# Godot Console
# ------------------------
# Implements performance monitor overlay
#
# ------------------------
# Author : Dmitry "Vortex" Koteroff
# Email  : krakean@outlook.com
# Date   : 06.12.2017

extends CanvasLayer

onready var perf_box = $PerfBox
onready var perf_txt = $PerfBox/PerfText

# Console variables
var _perf_enabled = false

# Console get-set stubs
var perf_enabled setget set_perf_enabled, get_perf_enabled

func set_perf_enabled(value):
	_perf_enabled = value
	
	if value:
		perf_box.show()
	else:
		perf_box.hide()
	
func get_perf_enabled():
	return _perf_enabled

func _ready():
	perf_txt.set_selection_enabled(false)
	perf_txt.set_focus_mode(Control.FOCUS_NONE)
	perf_box.hide()
	
	# Register cvars
	Console.register_cvar("perf_enabled", {
		desc = "Enable performance monitor",
		type = TYPE_BOOL,
		target = self
	})
	
func _process(delta):
	if not _perf_enabled:
		return
		
	var mon_fps     = Performance.get_monitor(Performance.TIME_FPS)
	var mon_vmem    = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	
	var placeholder = """[right][color=white]FPS:[/color] [color=yellow]%s[/color] (%.2f ms)
[color=white]VMem:[/color] [color=yellow]%.2f[/color] MB[/right]
"""
	 
	var outstr = placeholder % [mon_fps, 
	                            1000.0 / mon_fps,
	                            mon_vmem / 1024 / 1024 ]
	
	perf_txt.set_bbcode(outstr)	
	