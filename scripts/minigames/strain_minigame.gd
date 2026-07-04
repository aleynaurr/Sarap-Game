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

func _ready() -> void:
	_on_init()

func _on_init() -> void:
	_taps_done = 0
	_hide_all_sprites()
	
	if _lbl_status:
		_lbl_status.text = "Keep pressing SPACE or E to strain!"

	if big_mixer_bowl: big_mixer_bowl.visible = true
	if big_mixer_bowl_2: big_mixer_bowl_2.visible = false

	if GameManager.get("fanning_result_state") != null:
		_fanning_result = GameManager.get("fanning_result_state")
	else:
		_fanning_result = "perfect"
	
	match _fanning_result:
		"raw":
			if strainer_w_mix_not_fan: strainer_w_mix_not_fan.visible = true
			if fanning_1: fanning_1.visible = true 
		"under":
			if strainer_w_mix_1_more_fan: strainer_w_mix_1_more_fan.visible = true
			if fanning_1: fanning_1.visible = true
		"perfect":
			if strainer_w_mix_2_perfect: strainer_w_mix_2_perfect.visible = true
			if fanning_2_welldone: fanning_2_welldone.visible = true
		"toomuch":
			if strainer_w_mix_3_too_much: strainer_w_mix_3_too_much.visible = true
			if fanning_3: fanning_3.visible = true
		"burnt":
			if strainer_w_mix_4_burnt: strainer_w_mix_4_burnt.visible = true
			if fanning_4_fannedtoomuch: fanning_4_fannedtoomuch.visible = true

func _on_update(_delta: float, remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		
	if remaining <= 0.0:
		_calculate_and_complete()
		return

	if Input.is_action_just_pressed("interact_p%d" % player_number):
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
			if _fanning_result == "burnt" or _fanning_result == "toomuch":
				coconut_mixture_strained_alrd.modulate = Color(0.75, 0.65, 0.55)
			else:
				coconut_mixture_strained_alrd.modulate = Color(1.0, 1.0, 1.0)

func _hide_all_sprites() -> void:
	if big_mixer_bowl: big_mixer_bowl.visible = false
	if big_mixer_bowl_2: big_mixer_bowl_2.visible = false

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

func _force_finish() -> void:
	_calculate_and_complete()

func _calculate_and_complete() -> void:
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
			final_score = clampf(final_score - 0.4, 0.0, 1.0) # Flat deduction penalty

	if strained_mixture_flow: strained_mixture_flow.visible = false
	if strained_mixture_flow_2: strained_mixture_flow_2.visible = false
	
	if strainer_w_mix_not_fan: strainer_w_mix_not_fan.visible = false
	if strainer_w_mix_1_more_fan: strainer_w_mix_1_more_fan.visible = false
	if strainer_w_mix_2_perfect: strainer_w_mix_2_perfect.visible = false
	if strainer_w_mix_3_too_much: strainer_w_mix_3_too_much.visible = false
	if strainer_w_mix_4_burnt: strainer_w_mix_4_burnt.visible = false
	
	if fanning_1: fanning_1.visible = false
	if fanning_2_welldone: fanning_2_welldone.visible = false
	if fanning_3: fanning_3.visible = false
	if fanning_4_fannedtoomuch: fanning_4_fannedtoomuch.visible = false
	
	if big_mixer_bowl: big_mixer_bowl.visible = false
	if big_mixer_bowl_2: big_mixer_bowl_2.visible = false

	if _taps_done > 0:
		if coconut_mixture_strained_alrd: coconut_mixture_strained_alrd.visible = true
		
	complete_minigame(final_score)
