extends Node


const PACKET_READ_LIMIT: int = 32
var STEAM_ID: int = 0
var STEAM_USERNAME: String = ""
var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var DATA
var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 10
enum LOBBY_AVAILABILITY {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}

signal new_lobby_data

func _ready() -> void:
	Steam.connect("lobby_created", self, "_on_Lobby_Created")
	Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")
	Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
	Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
	Steam.connect("lobby_message", self, "_on_Lobby_Message")
	Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
	Steam.connect("lobby_invite", self, "_on_Lobby_Invite")
	Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")
	Steam.connect("persona_state_change", self, "_on_Persona_Change")
	Steam.connect("p2p_session_request", self, "_on_P2P_Session_Request")
	Steam.connect("p2p_session_connect_fail", self, "_on_P2P_Session_Connect_Fail")

	STEAM_ID = GlobalSteam.STEAM_ID

func _process(delta):
	if LOBBY_ID > 0:
		_read_All_P2P_Packets()


# Action functions

func _make_P2P_Handshake() -> void:
	print("Sending P2P handshake to the lobby")

	_send_P2P_Packet(0, {"message":"handshake", "from":STEAM_ID})

func _send_P2P_Packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var SEND_TYPE: int = Steam.P2P_SEND_RELIABLE
	var CHANNEL: int = 0

	# Create a data array to send the data through
	var DATA: PoolByteArray
	DATA.append_array(var2bytes(packet_data))

	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for MEMBER in LOBBY_MEMBERS:
				if MEMBER['steam_id'] != STEAM_ID:
					Steam.sendP2PPacket(MEMBER['steam_id'], DATA, SEND_TYPE, CHANNEL)
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, DATA, SEND_TYPE, CHANNEL)

func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)

		if PACKET.empty() or PACKET == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var PACKET_SENDER: int = PACKET['steam_id_remote']

		# Make the packet data readable
		var PACKET_CODE: PoolByteArray = PACKET['data']
		var READABLE: Dictionary = bytes2var(PACKET_CODE)

		# Print the packet to output
		print("Packet: "+str(READABLE))

func _read_All_P2P_Packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		_read_P2P_Packet()
		_read_All_P2P_Packets(read_count + 1)

func _request_Lobby_List() -> void:
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(3)

	print("Requesting a lobby list")
	Steam.requestLobbyList()

func _create_Lobby() -> void:
	# Make sure a lobby is not already set
	if LOBBY_ID == 0:
		Steam.createLobby(LOBBY_AVAILABILITY.PUBLIC, LOBBY_MAX_MEMBERS)

func _join_Lobby(lobbyID: int) -> void:
	print("Attempting to join lobby "+str(lobbyID)+"...")

	# Clear any previous lobby members lists, if you were in a previous lobby
	LOBBY_MEMBERS.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(lobbyID)

func _leave_Lobby() -> void:
	# If in a lobby, leave it
	if LOBBY_ID != 0:
		# Send leave request to Steam
		Steam.leaveLobby(LOBBY_ID)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		LOBBY_ID = 0

		# Close session with all users
		for MEMBERS in LOBBY_MEMBERS:
			# Make sure this isn't your Steam ID
			if MEMBERS['steam_id'] != STEAM_ID:
				# Close the P2P session
				Steam.closeP2PSessionWithUser(MEMBERS['steam_id'])

		# Clear the local lobby list
		LOBBY_MEMBERS.clear()

func _get_Lobby_Members() -> void:
	# Clear your previous lobby list
	LOBBY_MEMBERS.clear()

	# Get the number of members from this lobby from Steam
	var MEMBERS: int = Steam.getNumLobbyMembers(LOBBY_ID)

	# Get the data of these players from Steam
	for MEMBER in range(0, MEMBERS):
		# Get the member's Steam ID
		var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(LOBBY_ID, MEMBER)

		# Get the member's Steam name
		var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)

		# Add them to the list
		LOBBY_MEMBERS.append({"steam_id":STEAM_ID, "steam_name":STEAM_USERNAME})


# Steam callbacks

func _on_P2P_Session_Request(remote_id: int) -> void:
	# Get the requester's name
	var REQUESTER: String = Steam.getFriendPersonaName(remote_id)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)

	# Make the initial handshake
	_make_P2P_Handshake()

func _on_P2P_Session_Connect_Fail(steamID: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with "+str(steamID)+" [no error given].")

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with "+str(steamID)+" [target user not running the same game].")

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with "+str(steamID)+" [local user doesn't own app / game].")

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with "+str(steamID)+" [target user isn't connected to Steam].")

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with "+str(steamID)+" [connection timed out].")

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with "+str(steamID)+" [unused].")

	# Else no known error
	else:
		print("WARNING: Session failure with "+str(steamID)+" [unknown error "+str(session_error)+"].")

func _on_Lobby_Created(connect: int, lobby_id: int) -> void:
	if connect == 1:
		# Set the lobby ID
		LOBBY_ID = lobby_id
		print("Created a lobby: "+str(LOBBY_ID))

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(LOBBY_ID, true)

		# Set some lobby data
		Steam.setLobbyData(LOBBY_ID, "name", "Gramps' Lobby")
		Steam.setLobbyData(LOBBY_ID, "mode", "GodotSteam test")
		Steam.setLobbyData(LOBBY_ID, "flooshed", "flooshed")

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var RELAY: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: "+str(RELAY))

func _on_Lobby_Match_List(lobbies: Array) -> void:
	var lobby_data = []
	for lobbyId in lobbies:
#		if Steam.getLobbyData(lobbyId, "flooshed") != "flooshed":
#			continue
		lobby_data.push_back({
			"id": lobbyId,
			"name": Steam.getLobbyData(lobbyId, "name"),
			"mode": Steam.getLobbyData(lobbyId, "mode"),
			"numMembers": Steam.getNumLobbyMembers(lobbyId)
		})

	emit_signal("new_lobby_data", lobby_data)

func _on_Lobby_Joined(lobbyID: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == 1:
		# Set this lobby ID as your lobby ID
		LOBBY_ID = lobbyID

		# Get the lobby members
		_get_Lobby_Members()

		# Make the initial handshake
		_make_P2P_Handshake()

	# Else it failed for some reason
	else:
		# Get the failure reason
		var FAIL_REASON: String

		match response:
			2:	FAIL_REASON = "This lobby no longer exists."
			3:	FAIL_REASON = "You don't have permission to join this lobby."
			4:	FAIL_REASON = "The lobby is now full."
			5:	FAIL_REASON = "Uh... something unexpected happened!"
			6:	FAIL_REASON = "You are banned from this lobby."
			7:	FAIL_REASON = "You cannot join due to having a limited account."
			8:	FAIL_REASON = "This lobby is locked or disabled."
			9:	FAIL_REASON = "This lobby is community locked."
			10:	FAIL_REASON = "A user in the lobby has blocked you from joining."
			11:	FAIL_REASON = "A user you have blocked is in the lobby."

func _on_Lobby_Join_Requested(lobbyID: int, friendID: int) -> void:
	# Get the lobby owner's name
	var OWNER_NAME: String = Steam.getFriendPersonaName(friendID)

	print("Joining "+str(OWNER_NAME)+"'s lobby...")

	# Attempt to join the lobby
	_join_Lobby(lobbyID)

func _on_Lobby_Chat_Update(lobbyID: int, changedID: int, makingChangeID: int, chatState: int) -> void:
	# Get the user who has made the lobby change
	var CHANGER: String = Steam.getFriendPersonaName(changedID)

	# If a player has joined the lobby
	if chatState == 1:
		print(str(CHANGER)+" has joined the lobby.")

	# Else if a player has left the lobby
	elif chatState == 2:
		print(str(CHANGER)+" has left the lobby.")

	# Else if a player has been kicked
	elif chatState == 8:
		print(str(CHANGER)+" has been kicked from the lobby.")

	# Else if a player has been banned
	elif chatState == 16:
		print(str(CHANGER)+" has been banned from the lobby.")

	# Else there was some unknown change
	else:
		print(str(CHANGER)+" did... something.")

	# Update the lobby now that a change has occurred
	_get_Lobby_Members()

func _on_Persona_Change(steam_id: int, _flag: int) -> void:
	print("[STEAM] A user ("+str(steam_id)+") had information change, update the lobby list")

	# Update the player list
	_get_Lobby_Members()
