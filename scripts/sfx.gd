extends RefCounted
## Efeitos sonoros sintetizados em codigo (estilo 8-bit). Servem de placeholder ate existirem
## arquivos de som de verdade: para trocar, basta fazer get_stream() carregar um .wav/.ogg.
## Uso: Game.play_sfx("jump")

const RATE := 22050

static var _cache: Dictionary = {}


static func get_stream(sfx_name: String) -> AudioStreamWAV:
	if not _cache.has(sfx_name):
		_cache[sfx_name] = _make(sfx_name)
	return _cache[sfx_name]


## Cada som e uma lista de trechos [freq_inicial, freq_final, duracao_s].
static func _make(sfx_name: String) -> AudioStreamWAV:
	match sfx_name:
		"jump":
			return _build([[300.0, 620.0, 0.11]], "square", 0.22)
		"flower":
			return _build([[880.0, 880.0, 0.05], [1175.0, 1175.0, 0.05], [1568.0, 1568.0, 0.09]], "square", 0.18)
		"stomp":
			return _build([[320.0, 70.0, 0.14]], "square", 0.3)
		"hurt":
			return _build([[520.0, 120.0, 0.22]], "noise_square", 0.3)
		"death":
			return _build([[523.0, 523.0, 0.10], [392.0, 392.0, 0.10], [262.0, 110.0, 0.40]], "triangle", 0.4)
		"checkpoint":
			return _build([[523.0, 523.0, 0.07], [659.0, 659.0, 0.07], [784.0, 784.0, 0.12]], "square", 0.18)
		"life":
			return _build([[784.0, 784.0, 0.06], [988.0, 988.0, 0.06], [1319.0, 1319.0, 0.12]], "triangle", 0.35)
		"complete":
			return _build([[523.0, 523.0, 0.10], [659.0, 659.0, 0.10], [784.0, 784.0, 0.10],
				[1047.0, 1047.0, 0.28]], "square", 0.2)
		"select":
			return _build([[700.0, 700.0, 0.03]], "square", 0.12)
		"confirm":
			return _build([[660.0, 660.0, 0.04], [990.0, 990.0, 0.06]], "square", 0.16)
		"denied":
			return _build([[200.0, 160.0, 0.12]], "square", 0.18)
	push_warning("Sfx: som desconhecido '%s'" % sfx_name)
	return _build([[440.0, 440.0, 0.05]], "square", 0.1)


static func _build(segments: Array, wave: String, volume: float) -> AudioStreamWAV:
	var total := 0
	for seg: Array in segments:
		total += int(seg[2] * RATE)
	var data := PackedByteArray()
	data.resize(total * 2)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1234  # mesmo "ruido" sempre
	var i := 0
	var phase := 0.0
	for seg: Array in segments:
		var n := int(seg[2] * RATE)
		var dur: float = seg[2]
		for k in n:
			var t := float(k) / RATE
			var freq := lerpf(seg[0], seg[1], float(k) / n)
			phase = fmod(phase + freq / RATE, 1.0)
			var s := 0.0
			match wave:
				"square":
					s = 1.0 if phase < 0.5 else -1.0
				"triangle":
					s = 4.0 * absf(phase - 0.5) - 1.0
				"noise_square":
					s = (0.6 if phase < 0.5 else -0.6) + rng.randf_range(-0.4, 0.4)
			# Ataque e soltura curtos em cada trecho (sem estalos).
			var env := minf(1.0, t / 0.004) * minf(1.0, (dur - t) / 0.02)
			data.encode_s16(i * 2, int(clampf(s * env * volume, -1.0, 1.0) * 32767.0))
			i += 1

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
