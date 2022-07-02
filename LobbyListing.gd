extends Panel


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$LobbyCreateButton.connect("pressed", GlobalSteamLobby, "_create_Lobby")
	$LobbyLeaveButton.connect("pressed", GlobalSteamLobby, "_leave_Lobby")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if GlobalSteamLobby.LOBBY_ID > 0:
		$LobbyCreateButton.disabled = true
		$LobbyCreateButton.text = "In a lobby"
		$LobbyLeaveButton.disabled = false
		$LobbyLeaveButton.text = "Leave lobby"
	else:
		$LobbyCreateButton.disabled = false
		$LobbyCreateButton.text = "Create lobby"
		$LobbyLeaveButton.disabled = true
		$LobbyLeaveButton.text = "Not in a lobby"
	pass
