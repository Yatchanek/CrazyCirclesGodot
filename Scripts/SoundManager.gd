extends Node

var sounds = [preload("res://Assets/Sounds/circle.ogg"), 
			  preload("res://Assets/Sounds/circle2.ogg"),
			  preload("res://Assets/Sounds/circle2.ogg"), 
			  preload("res://Assets/Sounds/polygon.ogg"), 
			  preload("res://Assets/Sounds/polygon2.ogg"),
			  preload("res://Assets/Sounds/polygon3.ogg"),
			  preload("res://Assets/Sounds/fail.ogg"),
			  preload("res://Assets/Sounds/game_over.ogg"),
			  preload("res://Assets/Sounds/Heal.ogg")]
			
var music = [preload("res://Assets/Sounds/MenuMusic.ogg"),
			 preload("res://Assets/Sounds/Music.ogg"),
			 preload("res://Assets/Sounds/Music2.ogg"),
			 preload("res://Assets/Sounds/Music3.ogg")]

enum {
	CIRCLE_HIT,
	CIRCLE_HIT_2,
	CIRCLE_HIT_3,
	POLYGON_HIT,
	POLYGON_HIT_2,
	POLYGON_HIT_3,
	MISS,
	GAME_OVER,
	HEAL
}

enum {
	MENU_MUSIC,
	GAME_MUSIC_1,
	GAME_MUSIC_2,
	GAME_MUSIC_3
}

var current_track
var previous_music_volume


func _ready():
	previous_music_volume = $Music.volume_db
	current_track = 0

func play_effect(effect):
	for channel in get_children():
		if channel.name.begins_with("Channel") and !channel.is_playing():
			channel.stream = sounds[effect]
			channel.play()
			break

func play_music(track):
	current_track = track
	$Music.stream = music[current_track]
	$Music.play()
	$MusicTimer.wait_time = $Music.stream.get_length() - 2
	$MusicTimer.start()

func stop_effects():
	for channel in get_children():
		if channel.name.begins_with("Channel"):
			channel.stop()

func stop_music():
	$Music.stop()

func fade_out():

	previous_music_volume = $Music.volume_db

	$Tween.interpolate_property($Music, "volume_db", $Music.volume_db, -80, 2.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()

func fade_in():
	$Tween.interpolate_property($Music, "volume_db", -80, previous_music_volume, 2.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()	
	
func _on_EffectVolumeSlider_value_changed(value):
	for channel in get_children():
		if channel.name.begins_with("Channel"):
			channel.volume_db = value - 15
			if channel.volume_db < -30:
				channel.volume_db = -80
		

func _on_MusicVolumeSlider_value_changed(value):
	$Music.volume_db = value - 15
	if $Music.volume_db < -30:
		$Music.volume_db = -80
	previous_music_volume = $Music.volume_db	


func _on_MusicTimer_timeout():
	fade_out()
	yield($Tween, "tween_completed")
	play_music(wrapi(current_track + 1, 0, music.size()))
	fade_in()
