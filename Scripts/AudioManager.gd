extends Node
## Sound effects (SFX bus) and looping background music (Music bus).
## Lives as an autoload, so the music keeps playing across scene changes.

const PLAYLIST := [
	'res://Assets/Sound/exploration_v2_out.mp3',
	'res://Assets/Sound/nastelbom-folk-folk-music-602436.mp3',
]
@onready var jump_sfx: AudioStreamPlayer = $JumpSfx
@onready var coin_sfx: AudioStreamPlayer = $CoinSfx
var music: AudioStreamPlayer
var track: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	jump_sfx.bus = &'SFX'
	coin_sfx.bus = &'SFX'
	music = AudioStreamPlayer.new()
	music.name = 'Music'
	music.bus = &'Music'
	music.volume_db = -6.0
	add_child(music)
	# The two songs take turns, forever.
	music.finished.connect(func(): play_track(track + 1))
	play_track(0)

func play_track(index: int) -> void:
	track = index % PLAYLIST.size()
	music.stream = load(PLAYLIST[track])
	music.play()
