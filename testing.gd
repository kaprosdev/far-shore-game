extends Label


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSteam.connect("went_online", self, "display_steam_name")
	if GlobalSteam.IS_ONLINE:
		display_steam_name()
	pass # Replace with function body.

func display_steam_name():
	if GlobalSteam.IS_ONLINE:
		text = "Logged in as " + GlobalSteam.STEAM_USERNAME + "!"
		$LobbyInterface.visible = true
	else:
		text = "Not logged in"
		$LobbyInterface.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
