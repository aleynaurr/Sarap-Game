extends MinigameBase
# Mini-game: Straining Station (Mash/Tap to Strain Mixture)

# Configuration
const STRAIN_TAPS_NEEDED := 15
var _taps_done := 0
var _fanning_result := "perfect"

# UI Nodes
@onready var _lbl_timer: Label = $TimerLabel
@onready var _lbl_status: Label = $StatusLabel

@onready var big_mixer_bowl = $BigMixerBowl
@onready var big_mixer_bowl_2 = $BigMixerBowl2

@onready var fanning_1 = $Fanning1
@onready var fanning_2_welldone = $Fanning2Welldone
@onready var fanning_3 = $Fanning3
@onready var fanning_4_fannedtoomuch = $Fanning4Fannedtoomuch

@onready var strainer_w_mix_not_fan = $StrainerWMixNotFan
@onready var strainer_w_mix_1_more_fan = $StrainerWMix1MoreFan
@onready var strainer_w_mix_2_perfect = $StrainerWMix2Perfect
@onready var strainer_w_mix_3_too_much = $StrainerWMix3TooMuch
@onready var strainer_w_mix_4_burnt = $StrainerWMix4Burnt

@onready var strained_mixture_flow = $StrainedMixtureFlow
@onready var strained_mixture_flow_2 = $StrainedMixtureFlow2
@onready var coconut_mixture_strained_alrd = $finish

var _has_poured := false
var _is_pouring := false

func _ready() -> void:
	_on_init()

func _on_init() -> void:
	_taps_done = 0
	_hide_all_sprites()
	
	if _lbl_status:
		_lbl_status.text = "Press W or ↑ to pour!"

	if big_mixer_bowl: big_mixer_bowl.visible = true
	if big_mixer_bowl_2: big_mixer_bowl_2.visible = true

	if $Strainer: $Strainer.visible = true

	_fanning_result = GameManager.get_fanning_result_state(player_number)

	if _fanning_result == "":
		_fanning_result = "perfect"
		
	_has_poured = false
	_is_pouring = false
	
	match _fanning_result:
		"raw", "under":
			if fanning_1: fanning_1.visible = true
		"perfect":
			if fanning_2_welldone: fanning_2_welldone.visible = true
		"toomuch":
			if fanning_3: fanning_3.visible = true
		"burnt":
			if fanning_4_fannedtoomuch: fanning_4_fannedtoomuch.visible = true

func _on_update(_delta: float, remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % remaining
	
	if _is_pouring:
		return

	if not _has_poured:
		if Input.is_action_just_pressed("move_up_p%d" % player_number):
			_pour_mixture()
		return

	# Second step: Strain (S or Down Arrow repeatedly)
	if Input.is_action_just_pressed("move_down_p%d" % player_number):
		_taps_done += 1
		_update_straining_progression()

		if _taps_done >= STRAIN_TAPS_NEEDED:
			_calculate_and_complete()

func _update_straining_progression() -> void:
	if _taps_done % 2 == 0:
		if strained_mixture_flow: strained_mixture_flow.visible = true
		if strained_mixture_flow_2: strained_mixture_flow_2.visible = false
	else:
		if strained_mixture_flow: strained_mixture_flow.visible = false
		if strained_mixture_flow_2: strained_mixture_flow_2.visible = true

	if _taps_done >= STRAIN_TAPS_NEEDED * 0.5:
		if coconut_mixture_strained_alrd:
			coconut_mixture_strained_alrd.visible = true
			
			if _fanning_result == "burnt":
				coconut_mixture_strained_alrd.modulate = Color(0.3, 0.25, 0.25)
			elif _fanning_result == "toomuch":
				coconut_mixture_strained_alrd.modulate = Color(0.75, 0.65, 0.55)
			else:
				coconut_mixture_strained_alrd.modulate = Color(1.0, 1.0, 1.0)

func _hide_all_sprites() -> void:
	if $Strainer: $Strainer.visible = true

	if fanning_1: fanning_1.visible = false
	if fanning_2_welldone: fanning_2_welldone.visible = false
	if fanning_3: fanning_3.visible = false
	if fanning_4_fannedtoomuch: fanning_4_fannedtoomuch.visible = false
	
	if strainer_w_mix_not_fan: strainer_w_mix_not_fan.visible = false
	if strainer_w_mix_1_more_fan: strainer_w_mix_1_more_fan.visible = false
	if strainer_w_mix_2_perfect: strainer_w_mix_2_perfect.visible = false
	if strainer_w_mix_3_too_much: strainer_w_mix_3_too_much.visible = false
	if strainer_w_mix_4_burnt: strainer_w_mix_4_burnt.visible = false
	
	if strained_mixture_flow: strained_mixture_flow.visible = false
	if strained_mixture_flow_2: strained_mixture_flow_2.visible = false
	if coconut_mixture_strained_alrd: coconut_mixture_strained_alrd.visible = false
	
func _pour_mixture() -> void:
	_is_pouring = true
	_lbl_status.text = "Pouring..."
	if big_mixer_bowl_2: big_mixer_bowl_2.visible = false

	var pouring_sprite = _get_current_fanning_sprite()

	if pouring_sprite:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(pouring_sprite, "rotation_degrees", -45, 0.25)
		tween.tween_property(pouring_sprite, "position", Vector2(172, 173), 1.0)
		
		await tween.finished
		
		pouring_sprite.rotation_degrees = 0
		pouring_sprite.visible = false

	if has_node("PourEffect"):
		get_node("PourEffect").visible = true

	if big_mixer_bowl: big_mixer_bowl.visible = true
	if big_mixer_bowl_2: big_mixer_bowl_2.visible = true

	if $Strainer: $Strainer.visible = false

	match _fanning_result:
		"raw":
			if strainer_w_mix_not_fan: strainer_w_mix_not_fan.visible = true
		"under":
			if strainer_w_mix_1_more_fan: strainer_w_mix_1_more_fan.visible = true
		"perfect":
			if strainer_w_mix_2_perfect: strainer_w_mix_2_perfect.visible = true
		"toomuch":
			if strainer_w_mix_3_too_much: strainer_w_mix_3_too_much.visible = true
		"burnt":
			if strainer_w_mix_4_burnt: strainer_w_mix_4_burnt.visible = true

	if has_node("PourEffect"):
		get_node("PourEffect").visible = false

	_lbl_status.text = "Press S or ↓  repeatedly to strain!"
	_has_poured = true
	_is_pouring = false
	
func _get_current_fanning_sprite() -> TextureRect:
	match _fanning_result:
		"raw", "under":
			return fanning_1
		"perfect":
			return fanning_2_welldone
		"toomuch":
			return fanning_3
		"burnt":
			return fanning_4_fannedtoomuch
	return null

func _force_finish() -> void:
	_calculate_and_complete()

func _calculate_and_complete() -> void:
	set_process(false)
	
	var straining_score := clampf(float(_taps_done) / float(STRAIN_TAPS_NEEDED), 0.0, 1.0)
	var final_score := 1.0
	
	if straining_score < 1.0:
		if _lbl_status: _lbl_status.text = "Not strained well!"
		final_score = straining_score * 0.5
	else:
		if _lbl_status: _lbl_status.text = "Straining Complete!"
	
	match _fanning_result:
		"perfect":
			if final_score == 1.0:
				if _lbl_status: _lbl_status.text = "Perfect! No charcoal left!"
		
		"toomuch", "burnt":
			if _lbl_status: _lbl_status.text = "Ruined! Charcoal left in the mixture!"
			final_score = 0.0
			
		"raw", "under":
			if _lbl_status: _lbl_status.text = "Poor quality mixture!"
			final_score = clampf(final_score - 0.4, 0.0, 1.0)

	if strained_mixture_flow: strained_mixture_flow.visible = false
	if strained_mixture_flow_2: strained_mixture_flow_2.visible = false
	
	if strainer_w_mix_not_fan: strainer_w_mix_not_fan.visible = false
	if strainer_w_mix_1_more_fan: strainer_w_mix_1_more_fan.visible = false
	if strainer_w_mix_2_perfect: strainer_w_mix_2_perfect.visible = false
	if strainer_w_mix_3_too_much: strainer_w_mix_3_too_much.visible = false
	if strainer_w_mix_4_burnt: strainer_w_mix_4_burnt.visible = false
	
	if $Strainer: $Strainer.visible = true
	if big_mixer_bowl: big_mixer_bowl.visible = false
			
	if _taps_done > 0:
		if coconut_mixture_strained_alrd: coconut_mixture_strained_alrd.visible = true
		
	complete_minigame(final_score)
