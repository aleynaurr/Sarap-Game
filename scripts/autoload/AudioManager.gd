extends Node
# AudioManager — plays SFX and background music.
# Since we have no audio files, this generates simple beeps via AudioStreamGenerator
# and provides named hooks so audio can be swapped in later.

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

const SFX_CHOP     = "chop"
const SFX_SIZZLE   = "sizzle"
const SFX_SPLASH   = "splash"
const SFX_SUCCESS  = "success"
const SFX_FAIL     = "fail"
const SFX_CLICK    = "click"
const SFX_STEP     = "step"

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)

func play_music(_track_name: String) -> void:
	# Hook: load and play background music track by name
	pass

func stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()

func play_sfx(_sfx_name: String) -> void:
	# Hook: play a named sound effect
	pass
