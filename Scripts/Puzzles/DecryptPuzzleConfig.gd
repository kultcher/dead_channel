class_name DecryptPuzzleConfig extends Resource

enum Cipher { NONE, REPLACEMENT }

@export var cipher: Cipher = Cipher.NONE
@export var cipher_text: String = ""
@export var mapping_offset: int = 0
@export var keyspace_min: int = 3
@export var keyspace_max: int = 5

func ensure_generated(difficulty: int) -> void:
	if cipher != Cipher.NONE:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	match difficulty:
		1:
			cipher = Cipher.REPLACEMENT
			cipher_text = _generate_unique_cipher_text(rng, 4)
			mapping_offset = rng.randi_range(2, 4)
			keyspace_min = 2
			keyspace_max = 4
		_:
			cipher = Cipher.REPLACEMENT
			cipher_text = _generate_unique_cipher_text(rng, 4)
			mapping_offset = rng.randi_range(5, 10)
			keyspace_min = 3
			keyspace_max = 5

func _generate_unique_cipher_text(rng: RandomNumberGenerator, length: int) -> String:
	var alphabet: Array[String] = []
	for i in range(26):
		alphabet.append(String.chr(65 + i))
	alphabet.shuffle()
	return "".join(alphabet.slice(0, length))
