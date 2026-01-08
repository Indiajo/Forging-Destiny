extends Area2D

func enable_hurtbox():
	monitoring = true
	$CollisionShape2D.disabled = false

func disable_hurtbox():
	monitoring = false
	$CollisionShape2D.disabled = true
