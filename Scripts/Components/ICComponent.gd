# ICComponent.gd
# Component for adding IC protection to Signals

class_name ICComponent extends Resource

@export var modules: Array[Resource] = [] # Array of ICModule resources
