extends KinematicBody

var speed = 5
var velocity = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("general_up"):
		velocity.y += speed * delta
	if Input.is_action_pressed("general_down"):
		velocity.y -= speed * delta
	if Input.is_action_pressed("general_left"):
		velocity.x -= speed * delta
	if Input.is_action_pressed("general_right"):
		velocity.x += speed * delta

	global_translate(Vector3(velocity.y, 0, velocity.x))
	velocity = Vector2.ZERO
