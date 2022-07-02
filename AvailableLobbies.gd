extends Panel


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SelectedLobbyInfo.visible = false
	$SelectedLobbyInfo/LobbyJoinButton.connect("pressed", GlobalSteamLobby, "_request_Lobby_List")
	GlobalSteamLobby.connect("new_lobby_data", self, "_list_lobbies")
	GlobalSteamLobby._request_Lobby_List()
	pass # Replace with function body.

func _list_lobbies(lobbies: Array):
	var currindex = 0
	for lobby in lobbies:
		if lobby.name == "":
			continue
		$List.add_item(lobby.name)
		$List.set_item_metadata(currindex, lobby)
		currindex += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
