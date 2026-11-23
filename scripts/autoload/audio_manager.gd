extends Node

## Procedural AudioManager autoload.
## Generates cozy rain ambiance, a warm distant megastructure hum, and gentle movement SFX
## at startup using pure 16-bit PCM AudioStreamWAV synthesis (zero external assets).

const SAMPLE_RATE := 22050

var _rain_player: AudioStreamPlayer
var _hum_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var _sfx_footstep_stone: AudioStreamWAV
var _sfx_footstep_metal: AudioStreamWAV
var _sfx_jump: AudioStreamWAV
var _sfx_dash: AudioStreamWAV
var _sfx_land: AudioStreamWAV
var _sfx_ledge: AudioStreamWAV
var _sfx_chime: AudioStreamWAV
var _sfx_whoosh: AudioStreamWAV

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 472091
	_setup_players()
	_generate_audio_streams()
	_start_ambient()


func _exit_tree() -> void:
	if _rain_player:
		_rain_player.stop()
		_rain_player.stream = null
	if _hum_player:
		_hum_player.stop()
		_hum_player.stream = null
	for p in _sfx_pool:
		if is_instance_valid(p):
			p.stop()
			p.stream = null


func _setup_players() -> void:
	_rain_player = AudioStreamPlayer.new()
	_rain_player.name = "AmbientRain"
	_rain_player.volume_db = -12.0
	add_child(_rain_player)

	_hum_player = AudioStreamPlayer.new()
	_hum_player.name = "AmbientCityHum"
	_hum_player.volume_db = -18.5
	add_child(_hum_player)

	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		add_child(p)
		_sfx_pool.append(p)


func _generate_audio_streams() -> void:
	_rain_player.stream = _synth_rain_loop(4.0)
	_hum_player.stream = _synth_city_hum_loop(6.0)
	_sfx_footstep_stone = _synth_footstep(false)
	_sfx_footstep_metal = _synth_footstep(true)
	_sfx_jump = _synth_jump()
	_sfx_dash = _synth_dash()
	_sfx_land = _synth_land()
	_sfx_ledge = _synth_ledge()
	_sfx_chime = _synth_chime()
	_sfx_whoosh = _synth_whoosh()


func _start_ambient() -> void:
	if _rain_player.stream:
		_rain_player.play()
	if _hum_player.stream:
		_hum_player.play()


func play_footstep(on_metal: bool = false) -> void:
	var stream := _sfx_footstep_metal if on_metal else _sfx_footstep_stone
	_play_sfx(stream, _rng.randf_range(0.90, 1.14), -13.0 if on_metal else -14.5)


func play_jump() -> void:
	_play_sfx(_sfx_jump, _rng.randf_range(0.96, 1.06), -11.0)


func play_dash() -> void:
	_play_sfx(_sfx_dash, _rng.randf_range(0.94, 1.08), -9.5)


func play_land(impact_speed: float = 8.0) -> void:
	var gain := clampf(remap(impact_speed, 2.0, 16.0, -18.0, -8.5), -18.0, -8.0)
	_play_sfx(_sfx_land, _rng.randf_range(0.90, 1.05), gain)


func play_ledge_grab() -> void:
	_play_sfx(_sfx_ledge, _rng.randf_range(0.96, 1.05), -12.0)


func play_chime(pitch: float = 1.0) -> void:
	_play_sfx(_sfx_chime, pitch, -11.0)


func play_whoosh(pitch: float = 1.0) -> void:
	_play_sfx(_sfx_whoosh, pitch, -10.5)


func _play_sfx(stream: AudioStream, pitch: float, volume_db: float) -> void:
	if stream == null or _sfx_pool.is_empty():
		return
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


# --- Procedural WAV Builders ---

func _samples_to_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var count := samples.size()
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var s := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = count
	return wav


func _crossfade_loop(samples: PackedFloat32Array, fade_samples: int) -> PackedFloat32Array:
	var n := samples.size()
	var f := mini(fade_samples, n / 4)
	var out := samples.duplicate()
	for i in range(f):
		var t := float(i) / float(f)
		var end_idx := n - f + i
		out[i] = lerpf(samples[end_idx], samples[i], t)
	out.resize(n - f)
	return out


func _synth_rain_loop(duration: float) -> AudioStreamWAV:
	var total := int((duration + 0.35) * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)

	# Soft pink-ish filtered noise with occasional delicate droplet ticks.
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var lp := 0.0
	var drop_env := 0.0
	var drop_phase := 0.0
	var drop_freq := 1400.0

	for i in range(total):
		var white := _rng.randf_range(-1.0, 1.0)
		b0 = 0.996 * b0 + white * 0.055
		b1 = 0.960 * b1 + white * 0.085
		b2 = 0.720 * b2 + white * 0.115
		var pink := (b0 + b1 + b2) * 0.45

		# Gentle low-pass to keep the rain cozy and never harsh.
		lp = lp + 0.24 * (pink - lp)

		if _rng.randf() < 0.00055:
			drop_env = _rng.randf_range(0.06, 0.16)
			drop_freq = _rng.randf_range(900.0, 2100.0)
			drop_phase = 0.0

		var drop := 0.0
		if drop_env > 0.0005:
			drop_phase += TAU * drop_freq / SAMPLE_RATE
			drop = sin(drop_phase) * drop_env
			drop_env *= 0.992

		samples[i] = clampf(lp * 0.72 + drop * 0.45, -0.95, 0.95)

	var looped := _crossfade_loop(samples, int(0.35 * SAMPLE_RATE))
	return _samples_to_wav(looped, true)


func _synth_city_hum_loop(duration: float) -> AudioStreamWAV:
	# Exact periodic harmonics so the low ambient megastructure hum loops seamlessly.
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)

	var f1 := roundf(54.0 * duration) / duration
	var f2 := roundf(81.0 * duration) / duration
	var f3 := roundf(108.0 * duration) / duration
	var f4 := roundf(162.0 * duration) / duration
	var lfo_f := 1.0 / duration

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var swell := 0.85 + 0.15 * sin(TAU * lfo_f * t)
		var s := 0.0
		s += sin(TAU * f1 * t) * 0.42
		s += sin(TAU * f2 * t + 0.7) * 0.22
		s += sin(TAU * f3 * t + 1.4) * 0.14
		s += sin(TAU * f4 * t + 2.1) * 0.06 * (0.7 + 0.3 * sin(TAU * lfo_f * 2.0 * t))
		samples[i] = s * swell * 0.52

	return _samples_to_wav(samples, true)


func _synth_footstep(metal: bool) -> AudioStreamWAV:
	var duration := 0.095 if metal else 0.085
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * (38.0 if metal else 46.0)) * minf(t * 280.0, 1.0)
		var noise := _rng.randf_range(-1.0, 1.0)
		lp = lp + (0.38 if metal else 0.26) * (noise - lp)
		var tone := 0.0
		if metal:
			tone = (sin(TAU * 310.0 * t) * 0.28 + sin(TAU * 680.0 * t) * 0.16) * exp(-t * 32.0)
		else:
			# Soft damp puddle pat + low shoe tap
			tone = sin(TAU * 135.0 * t) * 0.32 * exp(-t * 50.0)
		samples[i] = (lp * 0.65 + tone) * env * 0.9

	return _samples_to_wav(samples, false)


func _synth_jump() -> AudioStreamWAV:
	var duration := 0.18
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var phase := 0.0
	var lp := 0.0

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var p := t / duration
		var freq := lerpf(190.0, 420.0, pow(p, 0.7))
		phase += TAU * freq / SAMPLE_RATE
		var env := sin(PI * p) * exp(-t * 6.0)
		lp = lp + 0.22 * (_rng.randf_range(-1.0, 1.0) - lp)
		samples[i] = (sin(phase) * 0.38 + lp * 0.28) * env

	return _samples_to_wav(samples, false)


func _synth_dash() -> AudioStreamWAV:
	var duration := 0.24
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0
	var phase := 0.0

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var p := t / duration
		var env := sin(PI * minf(p * 1.1, 1.0)) * exp(-t * 5.0)
		var cutoff := lerpf(0.45, 0.10, p)
		lp = lp + cutoff * (_rng.randf_range(-1.0, 1.0) - lp)
		phase += TAU * lerpf(520.0, 210.0, p) / SAMPLE_RATE
		samples[i] = (lp * 0.68 + sin(phase) * 0.18) * env

	return _samples_to_wav(samples, false)


func _synth_land() -> AudioStreamWAV:
	var duration := 0.15
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0
	var phase := 0.0

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 28.0) * minf(t * 240.0, 1.0)
		var freq := lerpf(150.0, 62.0, minf(t / duration, 1.0))
		phase += TAU * freq / SAMPLE_RATE
		lp = lp + 0.20 * (_rng.randf_range(-1.0, 1.0) - lp)
		samples[i] = (sin(phase) * 0.55 + lp * 0.45) * env

	return _samples_to_wav(samples, false)


func _synth_ledge() -> AudioStreamWAV:
	var duration := 0.11
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 36.0) * minf(t * 300.0, 1.0)
		lp = lp + 0.35 * (_rng.randf_range(-1.0, 1.0) - lp)
		var clink := sin(TAU * 460.0 * t) * 0.25 + sin(TAU * 820.0 * t) * 0.14
		samples[i] = (lp * 0.45 + clink) * env

	return _samples_to_wav(samples, false)


func _synth_chime() -> AudioStreamWAV:
	var duration := 0.55
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 6.5) * minf(t * 180.0, 1.0)
		var s := sin(TAU * 523.25 * t) * 0.45 + sin(TAU * 783.99 * t) * 0.30 + sin(TAU * 1046.5 * t) * 0.15
		samples[i] = s * env * 0.7

	return _samples_to_wav(samples, false)


func _synth_whoosh() -> AudioStreamWAV:
	var duration := 0.38
	var total := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0

	for i in range(total):
		var t := float(i) / float(SAMPLE_RATE)
		var p := t / duration
		var env := sin(PI * p)
		lp = lp + lerpf(0.12, 0.35, sin(PI * p)) * (_rng.randf_range(-1.0, 1.0) - lp)
		samples[i] = lp * env * 0.8

	return _samples_to_wav(samples, false)
