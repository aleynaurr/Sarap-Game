extends Node
# AudioManager — plays SFX and background music.

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _music_fade_tween: Tween
var _current_music_track: String = ""

const SFX_CHOP     = "chop"
const SFX_SIZZLE   = "sizzle"
const SFX_SPLASH   = "splash"
const SFX_SUCCESS  = "success"
const SFX_FAIL     = "fail"
const SFX_CLICK    = "click"
const SFX_STEP     = "step"

# ---- Music -----------------------------------------------------------

const MUSIC_DIR := "res://bgm/"
const MUSIC_TRACKS := {
	"menu": MUSIC_DIR + "menuselect.mp3",
	"getingredients": MUSIC_DIR + "getingredients.mp3",
	"kitchen": MUSIC_DIR + "kitchen.mp3",
}

const MUSIC_VOLUME_DB      := 0.0    # normal ("full") playback volume
const MUSIC_SILENT_DB      := -80.0  # effectively inaudible, used as the fade-in start / fade-out end
const MUSIC_FADE_IN_TIME   := 1.0
const MUSIC_FADE_OUT_TIME  := 1.75


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)


## Fades in and plays a named music track. If this track is already the
## current one and still playing, this is a no-op — so calling play_music("menu")
## again on returning to Main Menu will NOT restart or re-fade the song.
func play_music(track_name: String, fade_duration: float = MUSIC_FADE_IN_TIME) -> void:
	if track_name == _current_music_track and _music_player.playing:
		return

	var path: String = MUSIC_TRACKS.get(track_name, "")
	if path == "":
		push_warning("AudioManager: unknown music track '%s'" % track_name)
		return

	var stream := load(path)
	if stream == null:
		push_warning("AudioManager: could not load music '%s'" % path)
		return

	# Make sure it loops on its own if the player just idles on the menu
	# long enough for the track to reach its end.
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true

	_current_music_track = track_name
	_music_player.stream = stream
	_music_player.volume_db = MUSIC_SILENT_DB
	_music_player.play()

	_fade_music_to(MUSIC_VOLUME_DB, fade_duration)


## Fades the current music out to silence, then stops the player.
## Safe to call even if nothing is playing.
func fade_out_music(fade_duration: float = MUSIC_FADE_OUT_TIME) -> void:
	_current_music_track = ""
	_fade_music_to(MUSIC_SILENT_DB, fade_duration, true)


func stop_music() -> void:
	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()
	_current_music_track = ""
	if _music_player and _music_player.playing:
		_music_player.stop()


func _fade_music_to(target_db: float, duration: float, stop_after: bool = false) -> void:
	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_music_player, "volume_db", target_db, duration)
	if stop_after:
		_music_fade_tween.tween_callback(func(): _music_player.stop())


# ---- SFX ---------------------------------------------------------------

func play_sfx(_sfx_name: String) -> void:
	# Hook: play a named sound effect
	pass
