extends Window

@onready var label = $Panel/Layer/Label
@onready var layer = $Panel/Layer
@onready var target = $Target

var all_tiles = []
var target_tile: Control
var target_value

func _ready():
	randomize()
	populate()

func _process(delta: float):
	for child in layer.get_children():
		if child.position.x == 0:
			child.position.y += 10 * delta
		if child.position.x == 100:
			child.position.y += 20 * delta
		if child.position.x == 200:
			child.position.y += 30 * delta
		if child.position.x == 300:
			child.position.y += 20 * delta
		if child.position.x == 400:
			child.position.y += 10 * delta
		scroll(child)


func populate():
	var x: int = 0
	var y: int = 0
	var new_cell
	while x < 6:
		while y < 6:
			new_cell = label.duplicate()
			new_cell.position.x = 100 * x
			new_cell.position.y += 100 * y
			new_cell.text = generate_hex()
			new_cell.sniff_cell_clicked.connect(_check_sniff)
			layer.add_child(new_cell)
			all_tiles.append(new_cell)
			y += 1
		y = 0
		x += 1
	target_tile = all_tiles.pick_random()
	target_value = target_tile.text
	target.text = target_value

func scroll(child):
#	child.position.y += 1
	if child.position.y > 500:
		var new_cell = child.duplicate()
		new_cell.position.y = -100
		if new_cell.text != target_value:
			new_cell.text = generate_hex()
			while new_cell.text == target_value:
				new_cell.text = generate_hex()
			
		new_cell.sniff_cell_clicked.connect(_check_sniff)
		layer.add_child(new_cell)
		child.queue_free()
		
func generate_hex() -> String:
	var s = "%02X" % randi_range(0, 255)
	return s

func _check_sniff(text):
	print(text)
	if text == target_value:
		print("VICTORY")
