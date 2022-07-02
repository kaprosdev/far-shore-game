
extends Node

signal went_online

# Steam variables
var IS_ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = ""

func _ready() -> void:
	_initialize_Steam()

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	print("Did Steam initialize?: "+str(INIT))

	if INIT['status'] != 1:
		print("Failed to initialize Steam. "+str(INIT['verbal'])+" Shutting down...")
		get_tree().quit()

	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()

	emit_signal("went_online")
