extends SceneTree
## Generates Scenes/world.tscn: the Earth start plaza, three climbing zones
## (Floating Town above Earth, Cloud Sea, Space) and the summit.
##   godot --headless --path . --script res://tools/build_world.gd
## Re-running replaces direct edits to world.tscn and start_area.tscn.

const KAY := 'res://Assets/START BUIDER/Assets/gltf/'
const CITY := 'res://Assets/assets model 3d/'
const SPACE := 'res://Assets/Model Object Zone 3/'
const FOOD := 'res://Assets/FOOD MODEL ITEM/FOOD ITEM/Models/GLB format/'
const KAY_SCALE := 4.5
const ASSETS := {
	'car': [CITY + 'Sports Car1.glb', 0.0],
	'police': [CITY + 'Police Car .glb', 0.0],
	'lambo': [CITY + 'lambo car 1.glb', 0.0],
	'train': [CITY + 'Cargo Train.glb', 90.0],
	'building': [CITY + 'Large Building.glb', 0.0],
	'table1': [CITY + 'table1.glb', 90.0],
	'table2': [CITY + 'table2.glb', 0.0],
	'sofa': [CITY + 'sofa1.glb', 0.0],
	'tank': [CITY + 'Tank.glb', 0.0],
	'moto': [CITY + 'Motorcycle.glb', 90.0],
	'pipe': [CITY + 'Pipe1.glb', 0.0],
	'taxi': [KAY + 'car_taxi.gltf', 0.0],
	'crate': [KAY + 'box_A.gltf', 0.0],
	'asteroid': [SPACE + 'Asteroid 2 by J-Toastie - yuCzypJ0w4.glb', 0.0],
	'saucer': [SPACE + 'Flying saucer by Poly by Google - 6hu2h8v78mO.glb', 0.0],
	'ship': [SPACE + 'Spaceship by Liz Reddington - 5nWeu4IQXVX.glb', 0.0],
}
const FOODS := ['burger', 'donut-sprinkles', 'pizza', 'cupcake', 'ice-cream', 'watermelon', 'croissant', 'sandwich', 'cake', 'taco', 'banana', 'apple']
const FOOD_NAMES := ['เบอร์เกอร์', 'โดนัท', 'พิซซ่า', 'คัพเค้ก', 'ไอศกรีม', 'แตงโม', 'ครัวซองต์', 'แซนด์วิช', 'เค้ก', 'ทาโก้', 'กล้วย', 'แอปเปิล']

# Each step: kind, size, rise above previous landing (-1 = sits on the ground),
# edge gap, heading turn in degrees, motion, extras.
# motion: '' | 'slide:amplitude:period' | 'bob:amplitude:period' | 'spin:deg_per_s' | 'float:amplitude:period:spin'
# Each zone's route is generated (see generate_route) from these pools so the
# climb is long; a seed keeps every rebuild identical.
const STEPS_PER_ZONE := 50
const KINDS := [
	[['table2', 3.3], ['sofa', 3.8], ['car', 4.4], ['pipe', 1.9], ['train', 12.0], ['building', 6.0], ['police', 4.4], ['table1', 3.4], ['crate', 3.6], ['lambo', 4.6]],
	[['cloud', 2.2], ['cloud', 1.9], ['cloud', 2.0], ['sofa', 3.8], ['table1', 3.4], ['table2', 3.2], ['car', 4.4], ['crate', 3.2], ['pipe', 1.9], ['train', 12.0], ['lambo', 4.6], ['building', 6.0], ['crate', 3.6]],
	[['asteroid', 3.6], ['asteroid', 3.0], ['asteroid', 2.8], ['asteroid', 3.3], ['asteroid', 4.2], ['saucer', 6.0], ['ship', 6.5], ['pipe', 1.9], ['police', 4.4], ['car', 4.4], ['train', 12.0]],
]
## Longest edge-to-edge gap (at rest) a plain triple jump should have to cover.
const MAX_REST_GAP := 2.0
## Extra air kept between unrelated objects and around every planned jump.
const SPACING := 1.4
## Edges of a tilted object rise at most this much (metres).
const TILT_EDGE := 0.6
const ZONES := [
	{
		'name': 'เมืองลอยฟ้า', 'english': 'Floating Town',
		'greeting': 'สวัสดี Aof! ข้าคือลุงโอลี่',
		'message': '"เส้นทางลอยฟ้าโผล่มาหลังพายุใหญ่เมื่อคืน รถ ท่อ โต๊ะ โซฟา ลอยขึ้นไปจนทะลุเมฆ\nบางชิ้นยังขยับอยู่นะ รอจังหวะก่อนกระโดด แล้วอย่าลืมกินอาหารที่ลอยอยู่ จะได้กระโดดสูงขึ้น!"',
	},
	{
		'name': 'ทะเลเมฆ', 'english': 'Cloud Sea',
		'greeting': 'มาถึงทะเลเมฆแล้ว เก่งมาก!',
		'message': '"ยินดีต้อนรับสู่ทะเลเมฆ เหนือเมืองขึ้นมาอากาศจะเปลี่ยนไป\nก้อนเมฆนุ่มแต่ไม่นิ่ง บางก้อนลอยขึ้นลงหรือเลื่อนไปมา อย่ามองลงข้างล่างนะ แค่ขึ้นไปเรื่อย ๆ"',
		'pad': 'cloud',
	},
	{
		'name': 'ห้วงอวกาศ', 'english': 'Space Top',
		'greeting': 'นี่คืออวกาศ! ใกล้แล้วล่ะ',
		'message': '"เจ้ามาถึงห้วงอวกาศแล้ว! ที่นี่ไม่มีอะไรอยู่นิ่งเลย อุกกาบาต ยานบิน ทุกอย่างลอยไปมา\nเหยียบอุกกาบาตขึ้นไปเรื่อย ๆ ดาวแห่งความปรารถนารออยู่ข้างบนสุด ไปเลย Aof!"',
		'pad': 'dock',
	},
]
const SUMMIT_RISE := 1.8
const SUMMIT_GAP := 1.5
const PAD_RISE := [0.0, 1.6, 1.8]
const PAD_GAP := [0.0, 1.5, 1.5]

var level: Node3D
var platforms: Node3D
var checkpoints: Node3D
var foods: Node3D
var decor: Node3D
var manifest: Array = []
var route_points: Array[Vector3] = []
var side_platforms: Node3D
var shape_cache := {}
## Every placed climbable: {body, landing, info, yaw, motion, zone}
var placed: Array = []
## Planned jumps that must stay clear: [from landing, to landing]
var corridors: Array = []
var side_foods := 0
var spine_clashes := 0
## Physics-test feedback (tests/world_fixes.json): lower named main steps and
## remove side stones the test could not use. Applied without changing any
## random draw, so the rest of the layout stays identical.
var fixes := {'rise_cut': {}, 'drop_side': []}
var why := {}
func note(k: String) -> void:
	why[k] = why.get(k, 0) + 1
var rng := RandomNumberGenerator.new()
var thai_font: Font

func _initialize() -> void:
	call_deferred('build')

# ---------- helpers ---------- #

func add(node: Node, parent: Node) -> void:
	parent.add_child(node, true)
	node.owner = level

func own_all(node: Node) -> void:
	for child in node.get_children():
		if child.owner == null:
			child.owner = level
		own_all(child)

func material(color: Color, glow: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color, alpha)
	result.roughness = 0.85
	if alpha < 1.0:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = glow
	return result

func bounds_of(node: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mesh in node.find_children('*', 'MeshInstance3D', true, false):
		if mesh.mesh:
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
	return bounds

## Bounds of node's meshes expressed in frame's local space.
func bounds_in(node: Node3D, frame: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	var inverse := frame.global_transform.affine_inverse()
	for mesh in node.find_children('*', 'MeshInstance3D', true, false):
		if mesh.mesh:
			var box: AABB = (inverse * mesh.global_transform) * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
	return bounds

func top_at(faces: PackedVector3Array, x: float = 0.0, z: float = 0.0) -> float:
	var best := -INF
	for i in range(0, faces.size(), 3):
		var hit = Geometry3D.ray_intersects_triangle(Vector3(x, 1000, z), Vector3.DOWN, faces[i], faces[i + 1], faces[i + 2])
		if hit != null:
			best = maxf(best, hit.y)
	return best

## Instances an asset under parent (which must sit at the origin), scales it so
## its largest footprint (or height) equals size and centers it on X/Z with its
## base at Y=0.
func normalized_asset(path: String, parent: Node3D, size: float, yaw: float = 0.0, by_height: bool = false) -> Node3D:
	var asset: Node3D = load(path).instantiate()
	asset.name = 'Asset'
	add(asset, parent)
	asset.rotation.y += deg_to_rad(yaw)
	var bounds := bounds_in(asset, parent)
	var factor := size / (bounds.size.y if by_height else maxf(bounds.size.x, bounds.size.z))
	asset.scale *= factor
	bounds = bounds_in(asset, parent)
	asset.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	return asset

func collision_faces(asset: Node3D, body: Node3D) -> PackedVector3Array:
	var faces := PackedVector3Array()
	for mesh in asset.find_children('*', 'MeshInstance3D', true, false):
		if mesh.mesh:
			var transform: Transform3D = body.global_transform.affine_inverse() * mesh.global_transform
			for vertex in mesh.mesh.get_faces():
				faces.append(transform * vertex)
	return faces

func concave(body: Node3D, faces: PackedVector3Array, name: String = 'Collision') -> void:
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = name
	collision.shape = shape
	add(collision, body)

func box(parent: Node3D, name: String, size: Vector3, position: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = mat
	add(visual, parent)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = name + 'Collision'
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		collision.position = position
		add(collision, parent)
	return visual

func cylinder(parent: Node3D, name: String, radius: float, height: float, top: float, mat: Material, solid: bool = true) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 0.92
	mesh.height = height
	mesh.radial_segments = 32
	visual.mesh = mesh
	visual.position.y = top - height * 0.5
	visual.material_override = mat
	add(visual, parent)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = name + 'Collision'
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		collision.position.y = top - height * 0.5
		add(collision, parent)
	return visual

func kay(name: String, parent: Node3D, position: Vector3, yaw: float = 0.0, scale: float = KAY_SCALE) -> Node3D:
	var asset: Node3D = load(KAY + name + '.gltf').instantiate()
	asset.name = name.to_pascal_case()
	add(asset, parent)
	asset.position = position
	asset.rotation_degrees.y = yaw
	asset.scale = Vector3.ONE * scale
	return asset

func label3d(text: String, size: int = 48) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = thai_font
	label.font_size = size
	label.outline_size = 14
	label.outline_modulate = Color(0.08, 0.06, 0.14)
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	return label

# ---------- clouds ---------- #

func cloud_visual(parent: Node3D, radius: float, top: float, seed_value: int, alpha: float = 1.0) -> void:
	var local := RandomNumberGenerator.new()
	local.seed = seed_value
	var mat := material(Color(1, 1, 1), 0.15, alpha)
	mat.roughness = 1.0
	var puffs := 5 + int(radius)
	for i in puffs:
		var puff := MeshInstance3D.new()
		puff.name = 'Puff%d' % i
		var sphere := SphereMesh.new()
		var r := radius * local.randf_range(0.45, 0.7)
		sphere.radius = r
		sphere.height = r * 2.0
		sphere.radial_segments = 16
		sphere.rings = 8
		puff.mesh = sphere
		var angle := TAU * i / puffs + local.randf_range(-0.3, 0.3)
		var dist := radius * (0.0 if i == 0 else local.randf_range(0.35, 0.6))
		puff.position = Vector3(cos(angle) * dist, top - r * 0.55 + local.randf_range(-0.15, 0.1), sin(angle) * dist)
		puff.scale = Vector3(1, 0.62, 1)
		puff.material_override = mat
		add(puff, parent)

# ---------- route platforms ---------- #

# ---------- route generation ---------- #

func forward_of(angle: float) -> Vector3:
	return Vector3(-sin(angle), 0, -cos(angle))

func pick_motion(gen: RandomNumberGenerator, zone: int, kind: String, progress: float, long: bool) -> String:
	var small := kind in ['pipe', 'moto']
	if zone == 2:
		# Long things turn only a little; others tumble more.
		var spin := 4 if long else gen.randi_range(10, 20)
		var drift := 'float:%.1f:%.1f:%d' % [gen.randf_range(0.4, 0.7), gen.randf_range(4.0, 6.0), spin]
		var roll := gen.randf()
		if not small and not long and roll < 0.22 + 0.15 * progress:
			return drift + ':flip'
		if not small and roll < 0.5:
			return drift + ':rock'
		return drift
	var options := ['slide', 'bob', 'rock']
	if not long:
		options += ['spin', 'orbit']
		if not small and progress > 0.25:
			options += ['flip', 'flip']
	match options[gen.randi() % options.size()]:
		'slide': return 'slide:%.1f:%.1f' % [gen.randf_range(1.0, 1.8), gen.randf_range(3.5, 5.0)]
		'bob': return 'bob:%.1f:%.1f' % [gen.randf_range(0.5, 0.8), gen.randf_range(3.0, 4.0)]
		'spin': return 'spin:%d' % gen.randi_range(18, 40)
		'orbit': return 'orbit:%.1f:%.1f' % [gen.randf_range(1.0, 1.6), gen.randf_range(5.0, 8.0)]
		'rock': return 'rock:%d:%.1f' % [gen.randi_range(14, 22), gen.randf_range(2.8, 4.0)]
		'flip': return 'flip:%.1f:%.1f' % [gen.randf_range(2.5, 3.5), gen.randf_range(2.4, 3.2)]
	return ''

func parse_motion(text: String) -> Dictionary:
	if text == '':
		return {}
	var parts := text.split(':')
	var result := {'mode': parts[0]}
	match parts[0]:
		'slide', 'bob', 'orbit':
			result['amplitude'] = float(parts[1])
			result['period'] = float(parts[2])
		'spin':
			result['spin_speed'] = float(parts[1])
		'rock':
			result['spin_speed'] = float(parts[1])
			result['period'] = float(parts[2])
		'flip':
			result['hold_time'] = float(parts[1])
			result['flip_time'] = float(parts[2])
		'float':
			result['amplitude'] = float(parts[1])
			result['period'] = float(parts[2])
			result['spin_speed'] = float(parts[3])
			if parts.size() > 4:
				result['extra'] = parts[4]
	return result

func motion_text(motion: Dictionary) -> String:
	if motion.is_empty():
		return ''
	return str(motion['mode']) + (('+' + str(motion['extra'])) if motion.has('extra') else '')

## Distance from an object's center to its edge along a world direction.
## sweep = true includes the space its motion sweeps through.
func extent(info: Dictionary, yaw: float, motion: Dictionary, direction: Vector3, sweep: bool) -> float:
	var local := direction.rotated(Vector3.UP, -yaw)
	var hx: float = info['sx'] * 0.5
	var hz: float = info['sz'] * 0.5
	var rest := absf(local.x) * hx + absf(local.z) * hz
	if not sweep or motion.is_empty():
		return rest
	var mode: String = motion['mode']
	var extra: String = motion.get('extra', '')
	var flip_z := sqrt(hz * hz + pow(float(info['height']) * 0.5, 2))
	match mode:
		'spin':
			return sqrt(hx * hx + hz * hz)
		'orbit':
			return rest + float(motion['amplitude']) * 2.0
		'slide':
			return rest + float(motion['amplitude']) * absf(local.x)
		'flip':
			return absf(local.x) * hx + absf(local.z) * flip_z
		'float':
			var turn := deg_to_rad(float(motion['spin_speed']))
			var widest := rest
			for angle in [-turn, turn]:
				var turned := direction.rotated(Vector3.UP, -yaw - angle)
				widest = maxf(widest, absf(turned.x) * hx + absf(turned.z) * (flip_z if extra == 'flip' else hz))
			return widest + float(motion['amplitude']) * 0.5 * absf(direction.x)
	return rest

## Creates a body at the origin; returns its info (body, footprint, height, long).
func make_platform(kind: String, size: float, moving: bool, index: int, parent: Node3D, prefix: String = 'Platform') -> Dictionary:
	var body: StaticBody3D = StaticBody3D.new()
	if moving:
		var mover := AnimatableBody3D.new()
		# Physics sync would ignore transforms set while building; the
		# platform script turns it back on at runtime.
		mover.sync_to_physics = false
		body = mover
	body.name = prefix + '%02d' % index
	add(body, parent)
	if kind == 'cloud':
		cloud_visual(body, size, 0.0, index * 31 + (7 if prefix != 'Platform' else 0))
		var collision := CollisionShape3D.new()
		collision.name = 'CloudCollision'
		var shape := CylinderShape3D.new()
		shape.radius = size * 0.95
		shape.height = 1.0
		collision.shape = shape
		collision.position.y = -0.5
		add(collision, body)
		return {'body': body, 'sx': size * 1.9, 'sz': size * 1.9, 'height': 1.2, 'long': false}
	if kind == 'pipe':
		var asset := normalized_asset(ASSETS[kind][0], body, size)
		var bounds := bounds_of(asset)
		asset.position.y -= bounds.size.y
		# The warp pipe is hollow; a solid cylinder gives it a standable lid.
		var collision := CollisionShape3D.new()
		collision.name = 'PipeCollision'
		var shape := CylinderShape3D.new()
		shape.radius = size * 0.5
		shape.height = bounds.size.y
		collision.shape = shape
		collision.position.y = -bounds.size.y * 0.5
		add(collision, body)
		return {'body': body, 'sx': size, 'sz': size, 'height': bounds.size.y, 'long': false}
	var asset := normalized_asset(ASSETS[kind][0], body, size, ASSETS[kind][1])
	var key := '%s:%.2f' % [kind, size]
	var faces := collision_faces(asset, body)
	var center_top := top_at(faces)
	assert(is_finite(center_top), 'No surface above the center of ' + kind)
	asset.position.y -= center_top
	if not shape_cache.has(key):
		for v in faces.size():
			faces[v].y -= center_top
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		shape_cache[key] = shape
	# Identical objects share one collision shape (keeps world.tscn small).
	var collision := CollisionShape3D.new()
	collision.name = 'Collision'
	collision.shape = shape_cache[key]
	add(collision, body)
	var bounds := bounds_in(asset, body)
	var long := maxf(bounds.size.x, bounds.size.z) > 2.2 * minf(bounds.size.x, bounds.size.z)
	return {'body': body, 'sx': bounds.size.x, 'sz': bounds.size.z, 'height': bounds.size.y, 'long': long}

## Lean a floating object a little forward/back and left/right so it does not
## look placed on a ruler; long objects lean less so edges stay reachable.
func apply_tilt(body: Node3D, info: Dictionary, kind: String) -> void:
	# The building has roof ledges; tilting it can pinch gaps Aof gets wedged in.
	if kind in ['cloud', 'taxi', 'building']:
		return
	var pitch_max := minf(deg_to_rad(12.0), asin(minf(1.0, TILT_EDGE / maxf(0.1, info['sz'] * 0.5))))
	var roll_max := minf(deg_to_rad(12.0), asin(minf(1.0, TILT_EDGE / maxf(0.1, info['sx'] * 0.5))))
	body.rotation.x = rng.randf_range(-pitch_max, pitch_max)
	body.rotation.z = rng.randf_range(-roll_max, roll_max)

func attach_motion(body: Node3D, motion: Dictionary) -> void:
	if motion.is_empty():
		return
	body.set_script(load('res://Scripts/MovingPlatform.gd'))
	for key in motion:
		body.set(key, motion[key])
	body.set('phase', rng.randf_range(0.0, TAU))
	# Flips and seesaws turn around the middle of the object, not its top.
	body.set('pivot', bounds_in(body, body).get_center())

## Horizontal distance from point p to segment a-b.
func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func sweep_radius(info: Dictionary, yaw: float, motion: Dictionary) -> float:
	var radius := 0.0
	for k in 8:
		radius = maxf(radius, extent(info, yaw, motion, Vector3.FORWARD.rotated(Vector3.UP, PI * k / 8.0), true))
	return radius

## True when a new object touches nothing placed (with head room above
## surfaces) and sits in no planned jump.
func is_clear(landing: Vector3, info: Dictionary, yaw: float, motion: Dictionary, skips: Array = []) -> bool:
	var radius := sweep_radius(info, yaw, motion)
	var top := landing.y + 0.9
	var bottom := landing.y - float(info['height']) - 0.9
	for other in placed:
		var neighbour := false
		for skip in skips:
			if other['body'] == skip['body']:
				neighbour = true
		if neighbour:
			continue
		var o_land: Vector3 = other['landing']
		var dir := Vector3(landing.x - o_land.x, 0, landing.z - o_land.z)
		var horizontal := dir.length()
		dir = dir.normalized() if horizontal > 0.01 else Vector3.FORWARD
		var reach: float = extent(other['info'], other['yaw'], other['motion'], dir, true) + extent(info, yaw, motion, -dir, true) + SPACING
		var o_top: float = o_land.y + 2.4
		var o_bottom: float = o_land.y - float(other['info']['height']) - 0.3
		if horizontal < reach and top + 1.5 > o_bottom and bottom < o_top:
			return false
	var flat := Vector2(landing.x, landing.z)
	for corridor in corridors:
		var a: Vector3 = corridor[0]
		var b: Vector3 = corridor[1]
		var touches := false
		for skip in skips:
			if a == skip['landing'] or b == skip['landing']:
				touches = true
		if touches:
			continue
		var low := minf(a.y, b.y) - 0.4
		var high := maxf(a.y, b.y) + 3.4
		if segment_distance(flat, Vector2(a.x, a.z), Vector2(b.x, b.z)) < radius + SPACING and top > low and bottom < high:
			return false
	return true

## Edge gap at rest between two entries along the line joining them.
func rest_gap(a: Dictionary, b: Dictionary) -> float:
	var a_land: Vector3 = a['landing']
	var b_land: Vector3 = b['landing']
	var dir := Vector3(b_land.x - a_land.x, 0, b_land.z - a_land.z)
	var distance := dir.length()
	dir = dir.normalized()
	return distance - extent(a['info'], a['yaw'], a['motion'], dir, false) - extent(b['info'], b['yaw'], b['motion'], -dir, false)

## The straight jump from a to b passes no other object.
func corridor_clear(a: Dictionary, b: Dictionary) -> bool:
	var a_land: Vector3 = a['landing']
	var b_land: Vector3 = b['landing']
	var low := minf(a_land.y, b_land.y) - 0.4
	var high := maxf(a_land.y, b_land.y) + 3.4
	for other in placed:
		if other['body'] == a['body'] or other['body'] == b['body']:
			continue
		var o: Vector3 = other['landing']
		var r := sweep_radius(other['info'], other['yaw'], other['motion'])
		if segment_distance(Vector2(o.x, o.z), Vector2(a_land.x, a_land.z), Vector2(b_land.x, b_land.z)) < r + SPACING * 0.8 and o.y + 0.9 > low and o.y - float(other['info']['height']) < high:
			return false
	return true

## Plaza buildings, lights and parked cars are obstacles the route must avoid.
func register_plaza(plaza: Node3D) -> void:
	for holder in [plaza.get_node('Tiles'), plaza.get_node('Props')]:
		for asset in holder.get_children():
			var name := str(asset.name)
			if name.begins_with('Base') or name.begins_with('Road') or name.begins_with('Bush'):
				continue
			var b := bounds_in(asset, level)
			var landing := Vector3(b.get_center().x, b.end.y, b.get_center().z)
			placed.append(entry(asset, landing, {'sx': b.size.x, 'sz': b.size.z, 'height': b.size.y, 'long': false}, 0.0, {}, 0))

func entry(body: Node3D, landing: Vector3, info: Dictionary, yaw: float, motion: Dictionary, zone: int) -> Dictionary:
	return {'body': body, 'landing': landing, 'info': info, 'yaw': yaw, 'motion': motion, 'zone': zone}

func place_food(parent: Node3D, local_position: Vector3, index: int) -> void:
	var pickup := Area3D.new()
	var food_name: String = FOODS[index % FOODS.size()]
	pickup.name = 'Food_' + food_name.to_pascal_case()
	add(pickup, parent)
	pickup.position = local_position
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.85
	shape.shape = sphere
	add(shape, pickup)
	var visual := Node3D.new()
	visual.name = 'Visual'
	add(visual, pickup)
	normalized_asset(FOOD + food_name + '.glb', visual, 0.75)
	visual.position.y = 0.0
	var halo := OmniLight3D.new()
	halo.name = 'Glow'
	halo.light_color = Color(1.0, 0.8, 0.35)
	halo.light_energy = 1.4
	halo.omni_range = 2.5
	add(halo, pickup)
	pickup.set_script(load('res://Scripts/FoodPickup.gd'))
	pickup.set('food_name', FOOD_NAMES[index % FOODS.size()])
	pickup.add_to_group('Food', true)

# ---------- checkpoints ---------- #

func checkpoint_for(parent: Node3D, local_position: Vector3, index: int, zone: Dictionary) -> Area3D:
	var checkpoint := Area3D.new()
	checkpoint.name = 'OliCheckpoint%d' % (index + 1)
	add(checkpoint, checkpoints)
	var trigger := CollisionShape3D.new()
	trigger.name = 'Trigger'
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 2.4, 5.0)
	trigger.shape = shape
	trigger.position.y = 1.15
	add(trigger, checkpoint)
	var spawn := Marker3D.new()
	spawn.name = 'Spawn'
	spawn.position = Vector3(-0.6, 0.12, 0.6)
	add(spawn, checkpoint)
	var npc := StaticBody3D.new()
	npc.name = 'UncleOli'
	add(npc, checkpoint)
	normalized_asset('res://Assets/model/UncleOli/UncleOli.glb', npc, 1.7, 0.0, true)
	npc.position = Vector3(1.6, 0, -0.4)
	var npc_shape := CollisionShape3D.new()
	npc_shape.name = 'Body'
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.7
	npc_shape.shape = capsule
	npc_shape.position.y = 0.85
	add(npc_shape, npc)
	var bubble := label3d(zone['greeting'], 44)
	bubble.name = 'Bubble'
	bubble.position = Vector3(1.6, 2.35, -0.4)
	bubble.modulate = Color(1, 0.95, 0.75)
	add(bubble, checkpoint)
	var light := OmniLight3D.new()
	light.name = 'Glow'
	light.position = Vector3(1.6, 1.2, 0.2)
	light.omni_range = 4.0
	light.light_energy = 0.9
	light.light_color = Color(1.0, 0.75, 0.4)
	add(light, checkpoint)
	checkpoint.set_script(load('res://Scripts/OliCheckpoint.gd'))
	checkpoint.set('checkpoint_index', index)
	checkpoint.set('zone_name', zone['name'])
	checkpoint.set('greeting', zone['greeting'])
	checkpoint.set('message', zone['message'])
	# Position after the model is normalized at the origin.
	checkpoint.global_position = parent.global_position + local_position
	return checkpoint

## Wide landing pads at the start of zones 2 and 3 and at the summit.
func make_pad(kind: String, index: int) -> Array:
	var body := StaticBody3D.new()
	body.name = 'Platform%02d' % index
	add(body, platforms)
	var radius := 5.0
	match kind:
		'cloud':
			cloud_visual(body, radius + 1.0, 0.0, 777)
			var collision := CollisionShape3D.new()
			collision.name = 'IslandCollision'
			var shape := CylinderShape3D.new()
			shape.radius = radius
			shape.height = 1.2
			collision.shape = shape
			collision.position.y = -0.6
			add(collision, body)
		'dock', 'summit':
			var metal := material(Color(0.62, 0.66, 0.78))
			metal.metallic = 0.6
			metal.roughness = 0.35
			cylinder(body, 'Deck', radius, 0.6, 0.0, metal)
			var rim := MeshInstance3D.new()
			rim.name = 'GlowRim'
			var torus := TorusMesh.new()
			torus.inner_radius = radius - 0.12
			torus.outer_radius = radius + 0.12
			torus.rings = 48
			rim.mesh = torus
			rim.position.y = 0.0
			rim.material_override = material(Color(0.35, 0.9, 1.0) if kind == 'dock' else Color(1.0, 0.85, 0.35), 2.5)
			add(rim, body)
			cylinder(body, 'Underside', radius * 0.7, 1.6, -0.6, material(Color(0.32, 0.35, 0.45)), false)
			for i in 6:
				var angle := TAU * i / 6.0
				var lamp := MeshInstance3D.new()
				lamp.name = 'Beacon%d' % i
				var sphere := SphereMesh.new()
				sphere.radius = 0.18
				sphere.height = 0.36
				lamp.mesh = sphere
				lamp.position = Vector3(cos(angle) * (radius - 0.5), 0.15, sin(angle) * (radius - 0.5))
				lamp.material_override = material(Color(0.4, 1.0, 0.9) if kind == 'dock' else Color(1, 0.9, 0.4), 3.0)
				add(lamp, body)
	return [body, radius]

# ---------- summit ---------- #

func star_mesh(outer: float, inner: float, depth: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for i in 10:
		var angle := PI * 0.5 + TAU * i / 10.0
		var r := outer if i % 2 == 0 else inner
		points.append(Vector3(cos(angle) * r, sin(angle) * r, 0))
	var front := Vector3(0, 0, depth * 0.5)
	var back := Vector3(0, 0, -depth * 0.5)
	for i in 10:
		var a := points[i]
		var b := points[(i + 1) % 10]
		tool.add_vertex(front); tool.add_vertex(b); tool.add_vertex(a)
		tool.add_vertex(back); tool.add_vertex(a); tool.add_vertex(b)
	tool.generate_normals()
	return tool.commit()

func build_summit(pad: Node3D) -> void:
	var star := Area3D.new()
	star.name = 'WishStar'
	add(star, pad)
	star.position = Vector3(0, 2.2, -1.5)
	var trigger := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	trigger.shape = sphere
	add(trigger, star)
	var spinner := Node3D.new()
	spinner.name = 'Spinner'
	add(spinner, star)
	spinner.set_script(load('res://Scripts/FloatingDecor.gd'))
	spinner.set('bob_amplitude', 0.25)
	spinner.set('spin_speed', 60.0)
	var shape := MeshInstance3D.new()
	shape.name = 'Star'
	shape.mesh = star_mesh(1.1, 0.48, 0.45)
	shape.material_override = material(Color(1.0, 0.86, 0.3), 4.0)
	add(shape, spinner)
	var light := OmniLight3D.new()
	light.name = 'StarLight'
	light.light_color = Color(1.0, 0.85, 0.45)
	light.light_energy = 4.0
	light.omni_range = 10.0
	add(light, star)
	var sparkle := CPUParticles3D.new()
	sparkle.name = 'Sparkles'
	sparkle.amount = 40
	sparkle.lifetime = 1.6
	sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparkle.emission_sphere_radius = 1.3
	sparkle.gravity = Vector3(0, 0.4, 0)
	sparkle.initial_velocity_min = 0.1
	sparkle.initial_velocity_max = 0.5
	sparkle.scale_amount_min = 0.05
	sparkle.scale_amount_max = 0.12
	var dot := SphereMesh.new()
	dot.radius = 0.5
	dot.height = 1.0
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = material(Color(1, 0.95, 0.6), 3.0)
	sparkle.mesh = dot
	add(sparkle, star)
	star.set_script(load('res://Scripts/WishStar.gd'))
	var keeper := Node3D.new()
	keeper.name = 'StarKeeper'
	add(keeper, pad)
	normalized_asset('res://Assets/model/StarKeeper/StarKeeper.glb', keeper, 2.3, 0.0, true)
	keeper.position = Vector3(2.6, 0.05, -2.2)
	keeper.set_script(load('res://Scripts/FloatingDecor.gd'))
	keeper.set('bob_amplitude', 0.12)
	keeper.set('bob_period', 3.0)
	keeper.set('spin_speed', 0.0)
	var aura := OmniLight3D.new()
	aura.name = 'Aura'
	aura.position.y = 1.6
	aura.light_color = Color(0.65, 0.7, 1.0)
	aura.light_energy = 1.5
	aura.omni_range = 4.0
	add(aura, keeper)
	var title := label3d('ผู้พิทักษ์ดวงดาว', 40)
	title.name = 'Title'
	title.position.y = 2.75
	title.modulate = Color(0.8, 0.85, 1.0)
	add(title, keeper)
	keeper.rotation_degrees.y = -30.0

# ---------- start plaza (Earth) ---------- #

func build_start_area() -> Node3D:
	var area := StaticBody3D.new()
	area.name = 'StartArea'
	add(area, level)
	var tiles := Node3D.new()
	tiles.name = 'Tiles'
	add(tiles, area)
	var props := Node3D.new()
	props.name = 'Props'
	add(props, area)
	var tile := 2.0 * KAY_SCALE
	var buildings := ['building_A', 'building_B', 'building_C', 'building_D', 'building_E', 'building_F', 'building_G', 'building_H']
	var b := 0
	for i in range(-2, 3):
		for j in range(-2, 3):
			var center := Vector3(i * tile, -0.1 * KAY_SCALE, j * tile)
			var road_x := i == 0
			var road_z := j == 0
			if road_x and road_z:
				kay('road_junction', tiles, center)
			elif road_x:
				kay('road_straight', tiles, center, 90.0)
			elif road_z:
				kay('road_straight', tiles, center, 0.0)
			elif absi(i) == 2 or absi(j) == 2:
				# Outer ring of buildings, facing the middle of the plaza.
				var yaw := 0.0
				if absi(j) == 2 and absi(i) < 2:
					yaw = 0.0 if j > 0 else 180.0
				else:
					yaw = 90.0 if i > 0 else -90.0
				kay(buildings[b % buildings.size()], tiles, center, yaw + 180.0)
				b += 1
			else:
				kay('base', tiles, center)
	# Street furniture on the inner sidewalk tiles.
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var c := Vector3(corner.x * tile, 0, corner.y * tile)
		kay('streetlight', props, c + Vector3(-corner.x * 3.6, 0, -corner.y * 3.6), 45.0 if corner.x * corner.y > 0 else -45.0)
		kay('bench', props, c + Vector3(0, 0, -corner.y * 2.5), 0.0 if corner.y > 0 else 180.0)
		kay('bush', props, c + Vector3(corner.x * 2.5, 0, corner.y * 2.5), 0.0, 6.0)
		kay('bush', props, c + Vector3(corner.x * 1.0, 0, corner.y * 3.2), 40.0, 5.0)
		kay('trash_A', props, c + Vector3(-corner.x * 1.2, 0, -corner.y * 3.4))
	kay('firehydrant', props, Vector3(-tile + 3.4, 0, -3.6))
	kay('dumpster', props, Vector3(tile - 2.0, 0, tile - 2.5), 90.0)
	kay('box_A', props, Vector3(tile + 1.0, 0, -tile + 1.4), 15.0)
	kay('box_B', props, Vector3(tile + 2.6, 0, -tile + 2.2), -10.0)
	kay('trafficlight_A', props, Vector3(3.9, 0, 3.9), 180.0)
	kay('trafficlight_B', props, Vector3(-3.9, 0, -3.9))
	kay('watertower', props, Vector3(-tile * 3.2, 0, tile * 0.8), 0.0, 7.0)
	kay('car_sedan', props, Vector3(2.0, 0.27, 7.5), 0.0)
	kay('car_stationwagon', props, Vector3(-7.0, 0.27, 2.0), 90.0)
	kay('car_police', props, Vector3(9.5, 0.27, -2.0), -90.0)
	kay('car_hatchback', props, Vector3(2.2, 0.27, 18.5), 180.0)
	# Collide with everything except bushes.
	var faces := PackedVector3Array()
	for holder in [tiles, props]:
		for asset in holder.get_children():
			if str(asset.name).begins_with('Bush'):
				continue
			faces.append_array(collision_faces(asset, area))
	concave(area, faces, 'CityCollision')
	return area

func build_earth() -> void:
	var earth := StaticBody3D.new()
	earth.name = 'Earth'
	add(earth, level)
	var grass := material(Color(0.42, 0.66, 0.36))
	grass.roughness = 1.0
	box(earth, 'Ground', Vector3(700, 1, 700), Vector3(0, -0.62, 0), grass, true)
	var skyline := Node3D.new()
	skyline.name = 'Skyline'
	add(skyline, decor)
	var buildings := ['building_A', 'building_B', 'building_C', 'building_D', 'building_E', 'building_F', 'building_G', 'building_H']
	for i in 46:
		var angle := TAU * i / 46.0 + rng.randf_range(-0.05, 0.05)
		var distance := rng.randf_range(70.0, 130.0)
		var position := Vector3(cos(angle) * distance, -0.1, sin(angle) * distance)
		kay(buildings[i % buildings.size()], skyline, position, rad_to_deg(-angle) + 90.0, rng.randf_range(5.0, 9.0))
	for i in 60:
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(30.0, 66.0)
		var position := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		if absf(position.x) < 26.0 and absf(position.z) < 26.0:
			continue
		kay('bush', skyline, position, rng.randf_range(0, 360), rng.randf_range(10.0, 18.0))

# ---------- zone scenery ---------- #

func far_from_route(point: Vector3, clearance: float) -> bool:
	for p in route_points:
		if Vector2(p.x - point.x, p.z - point.z).length() < clearance and absf(p.y - point.y) < 10.0:
			return false
	return true

func scatter_clouds(center: Vector3, low: float, high: float, count: int, min_r: float, max_r: float, alpha: float, name: String) -> void:
	var layer := Node3D.new()
	layer.name = name
	add(layer, decor)
	var made := 0
	var tries := 0
	while made < count and tries < count * 20:
		tries += 1
		var angle := rng.randf_range(0, TAU)
		var distance := rng.randf_range(10.0, 140.0)
		var position := center + Vector3(cos(angle) * distance, rng.randf_range(low, high) - center.y, sin(angle) * distance)
		var radius := rng.randf_range(min_r, max_r)
		if not far_from_route(position, radius + 7.0):
			continue
		var puff := Node3D.new()
		puff.name = 'Cloud%d' % made
		add(puff, layer)
		puff.position = position
		cloud_visual(puff, radius, 0.0, 1000 + made, alpha)
		puff.set_script(load('res://Scripts/FloatingDecor.gd'))
		puff.set('bob_amplitude', rng.randf_range(0.3, 1.0))
		puff.set('spin_speed', rng.randf_range(-2.0, 2.0))
		puff.set('drift', Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3)))
		puff.set('phase', rng.randf_range(0, TAU))
		made += 1

## Non-solid floating city islands (like the title poster) and drifting junk.
func floating_scenery(center: Vector3, zone_heights: Array) -> void:
	var islands := Node3D.new()
	islands.name = 'FloatingIslands'
	add(islands, decor)
	var rock := material(Color(0.47, 0.43, 0.4))
	var soil := material(Color(0.36, 0.55, 0.3))
	var buildings := ['building_A', 'building_B', 'building_C', 'building_D', 'building_E', 'building_F', 'building_G', 'building_H']
	var made := 0
	var tries := 0
	while made < 22 and tries < 400:
		tries += 1
		var angle := rng.randf_range(0, TAU)
		var distance := rng.randf_range(24.0, 70.0)
		var position := center + Vector3(cos(angle) * distance, rng.randf_range(10.0, zone_heights[1] + 10.0), sin(angle) * distance)
		if not far_from_route(position, 14.0) or (absf(position.x) < 34.0 and absf(position.z) < 34.0 and position.y < 24.0):
			continue
		var island := Node3D.new()
		island.name = 'Island%d' % made
		add(island, islands)
		island.position = position
		var tiles := 1 if rng.randf() < 0.6 else 2
		for t in tiles:
			kay('base', island, Vector3(t * 9.0 - (tiles - 1) * 4.5, 0, 0))
			if rng.randf() < 0.8:
				kay(buildings[rng.randi() % buildings.size()], island, Vector3(t * 9.0 - (tiles - 1) * 4.5, 0.05, 0), rng.randf_range(0, 360), KAY_SCALE * rng.randf_range(0.7, 1.0))
		var grass := MeshInstance3D.new()
		grass.name = 'Soil'
		var cap := CylinderMesh.new()
		cap.top_radius = 4.6 * tiles
		cap.bottom_radius = 4.2 * tiles
		cap.height = 0.6
		grass.mesh = cap
		grass.position.y = -0.3
		grass.material_override = soil
		add(grass, island)
		var under := MeshInstance3D.new()
		under.name = 'Rock'
		var cone := CylinderMesh.new()
		cone.top_radius = 4.3 * tiles
		cone.bottom_radius = 0.6
		cone.height = rng.randf_range(5.0, 8.0)
		cone.radial_segments = 7
		under.mesh = cone
		under.position.y = -0.6 - cone.height * 0.5
		under.material_override = rock
		add(under, island)
		for b in rng.randi_range(2, 4):
			kay('bush', island, Vector3(rng.randf_range(-3.5, 3.5) * tiles, 0.05, rng.randf_range(-3.5, 3.5)), rng.randf_range(0, 360), rng.randf_range(4.0, 7.0))
		island.rotation_degrees.y = rng.randf_range(0, 360)
		island.set_script(load('res://Scripts/FloatingDecor.gd'))
		island.set('bob_amplitude', rng.randf_range(0.5, 1.2))
		island.set('bob_period', rng.randf_range(6.0, 10.0))
		island.set('spin_speed', rng.randf_range(-1.5, 1.5))
		island.set('phase', rng.randf_range(0, TAU))
		made += 1
	# Junk swept up by the storm: tumbling slowly through the town and clouds.
	var junk := Node3D.new()
	junk.name = 'FloatingJunk'
	add(junk, decor)
	var things := [['car', 4.4], ['police', 4.4], ['sofa', 3.8], ['table1', 3.4], ['tank', 7.0], ['moto', 3.0], ['lambo', 4.6], ['train', 12.0], ['pipe', 1.9]]
	made = 0
	tries = 0
	while made < 40 and tries < 600:
		tries += 1
		var angle := rng.randf_range(0, TAU)
		var distance := rng.randf_range(16.0, 75.0)
		var position := center + Vector3(cos(angle) * distance, rng.randf_range(6.0, zone_heights[2] - 4.0), sin(angle) * distance)
		var pick: Array = things[rng.randi() % things.size()]
		if not far_from_route(position, float(pick[1]) * 0.5 + 9.0) or (absf(position.x) < 34.0 and absf(position.z) < 34.0 and position.y < 22.0):
			continue
		var holder := Node3D.new()
		holder.name = 'Junk%d' % made
		add(holder, junk)
		normalized_asset(ASSETS[pick[0]][0], holder, pick[1] * rng.randf_range(0.8, 1.2))
		holder.position = position
		holder.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0, TAU), rng.randf_range(-0.6, 0.6))
		holder.set_script(load('res://Scripts/FloatingDecor.gd'))
		holder.set('bob_amplitude', rng.randf_range(0.4, 1.4))
		holder.set('spin_speed', rng.randf_range(-8, 8))
		holder.set('tumble', Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10)))
		holder.set('phase', rng.randf_range(0, TAU))
		made += 1

func space_scenery(center: Vector3, base_y: float, span: float) -> void:
	var k := span / 30.0
	var space := Node3D.new()
	space.name = 'SpaceScenery'
	add(space, decor)
	# Planets are fixed backdrop pieces; they never move.
	var planet := Node3D.new()
	planet.name = 'Planet'
	add(planet, space)
	normalized_asset(SPACE + 'Planet by Quaternius - 5zzi8WUMXj.glb', planet, 55.0)
	planet.position = center + Vector3(-120, base_y + 10 - center.y, -90)
	var moon := Node3D.new()
	moon.name = 'Moon'
	add(moon, space)
	normalized_asset(SPACE + 'Moon by Poly by Google - 9OPocAqXM0u.glb', moon, 40.0)
	moon.position = center + Vector3(110, base_y + span * 0.8 - center.y, 70)
	var station := Node3D.new()
	station.name = 'SpaceStation'
	add(station, space)
	normalized_asset(SPACE + 'International Space Station by Poly by Google - d3Fq5H6ne8E.glb', station, 45.0)
	station.position = center + Vector3(60, base_y + span * 0.5 - center.y, -80)
	station.set_script(load('res://Scripts/FloatingDecor.gd'))
	station.set('bob_amplitude', 1.5)
	station.set('bob_period', 14.0)
	station.set('spin_speed', 1.5)
	# Big ships cruising around the route (scenery, bigger than Aof).
	var ships := [['saucer', 14.0, Vector3(-38, 12 * k, 30)], ['ship', 18.0, Vector3(42, 4 * k, 26)], ['saucer', 10.0, Vector3(30, 26 * k, -40)], ['ship', 12.0, Vector3(-30, 30 * k, -36)], ['saucer', 16.0, Vector3(40, 20 * k, 38)], ['ship', 15.0, Vector3(-44, 8 * k, -10)]]
	for i in ships.size():
		var ship := Node3D.new()
		ship.name = 'Cruiser%d' % i
		add(ship, space)
		normalized_asset(ASSETS[ships[i][0]][0], ship, ships[i][1])
		ship.position = center + Vector3(ships[i][2].x, base_y + ships[i][2].y - center.y, ships[i][2].z)
		ship.set_script(load('res://Scripts/FloatingDecor.gd'))
		ship.set('bob_amplitude', 1.2)
		ship.set('bob_period', 7.0 + i)
		ship.set('spin_speed', 4.0 if ships[i][0] == 'saucer' else 0.0)
		ship.set('drift', Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)))
		ship.set('drift_period', 40.0 + i * 6)
	# Small drifting rocks.
	for i in 110:
		var position := center + Vector3(rng.randf_range(-80, 80), base_y + rng.randf_range(-6, span + 8) - center.y, rng.randf_range(-70, 70))
		if not far_from_route(position, 9.0):
			continue
		var rock := Node3D.new()
		rock.name = 'Rock%d' % i
		add(rock, space)
		normalized_asset(ASSETS['asteroid'][0], rock, rng.randf_range(1.5, 5.0))
		rock.position = position
		rock.rotation = Vector3(rng.randf_range(0, TAU), rng.randf_range(0, TAU), 0)
		rock.set_script(load('res://Scripts/FloatingDecor.gd'))
		rock.set('bob_amplitude', rng.randf_range(0.4, 1.4))
		rock.set('spin_speed', rng.randf_range(-12, 12))
		rock.set('tumble', Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-25, 25)))
		rock.set('phase', rng.randf_range(0, TAU))
	# Star field: fades in with the space zone (see World.gd).
	var stars := MultiMeshInstance3D.new()
	stars.name = 'StarField'
	add(stars, decor)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var dot := SphereMesh.new()
	dot.radius = 0.6
	dot.height = 1.2
	dot.radial_segments = 4
	dot.rings = 2
	multimesh.mesh = dot
	multimesh.instance_count = 1400
	for i in multimesh.instance_count:
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.35, 1), rng.randf_range(-1, 1)).normalized()
		var scale := rng.randf_range(0.4, 1.4)
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * scale), center + direction * rng.randf_range(260, 330)))
	stars.multimesh = multimesh
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	star_mat.albedo_color = Color(1, 1, 1, 0)
	stars.material_override = star_mat
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ---------- build ---------- #

func build() -> void:
	rng.seed = 4242
	if FileAccess.file_exists('res://tests/world_fixes.json'):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string('res://tests/world_fixes.json'))
		if parsed is Dictionary:
			fixes.merge(parsed, true)
	thai_font = load('res://Assets/Fonts/NotoSansThai.ttf')
	level = Node3D.new()
	level.name = 'World'
	root.add_child(level)
	level.set_script(load('res://Scripts/World.gd'))
	platforms = Node3D.new()
	platforms.name = 'Platforms'
	add(platforms, level)
	checkpoints = Node3D.new()
	checkpoints.name = 'Checkpoints'
	add(checkpoints, level)
	decor = Node3D.new()
	decor.name = 'Decor'
	add(decor, level)
	build_earth()
	var plaza := build_start_area()
	var zone_heights: Array = []
	var zone_names: Array = []
	# Zone 1 checkpoint sits in the plaza.
	checkpoint_for(plaza, Vector3(-2.6, 0.0, -9.0), 0, ZONES[0])
	zone_heights.append(0.0)
	zone_names.append(ZONES[0]['name'])
	side_platforms = Node3D.new()
	side_platforms.name = 'SidePlatforms'
	add(side_platforms, level)
	var gen := RandomNumberGenerator.new()
	gen.seed = 2026
	var heading := 0.0
	var food_index := 0
	var index := 1
	# The plaza exit counts as the first "platform" of the spine.
	var start_info := {'sx': 4.0, 'sz': 4.0, 'height': 0.5, 'long': false}
	var previous := entry(plaza, Vector3(0, 0, -21.0), start_info, 0.0, {}, 0)
	register_plaza(plaza)
	var spine: Array = []
	var summit: Node3D
	for z in ZONES.size():
		var zone: Dictionary = ZONES[z]
		if z > 0:
			var pad_kind: String = zone['pad']
			var made := make_pad(pad_kind, index)
			var pad: Node3D = made[0]
			var pad_info := {'sx': made[1] * 2.0, 'sz': made[1] * 2.0, 'height': 1.0, 'long': false}
			var direction := forward_of(heading)
			var distance: float = extent(previous['info'], previous['yaw'], previous['motion'], direction, true) + PAD_GAP[z] + made[1]
			var landing: Vector3 = previous['landing'] + direction * distance
			landing.y = previous['landing'].y + PAD_RISE[z]
			pad.position = landing
			pad.rotation.y = heading
			checkpoint_for(pad, Vector3(-0.5, 0, 0.5).rotated(Vector3.UP, heading), z, zone)
			zone_heights.append(landing.y)
			zone_names.append(zone['name'])
			record(pad, pad_kind, landing.y, made[1], heading, z, '')
			var pad_entry := entry(pad, landing, pad_info, heading, {}, z)
			corridors.append([previous['landing'], landing])
			placed.append(pad_entry)
			spine.append(pad_entry)
			previous = pad_entry
			index += 1
		var pool: Array = KINDS[z]
		var last_kind := ''
		for i in STEPS_PER_ZONE:
			var progress := float(i) / STEPS_PER_ZONE
			var pick: Array = pool[gen.randi() % pool.size()]
			while (pick[0] == last_kind and not pick[0] in ['cloud', 'asteroid']) or (last_kind == 'building' and pick[0] == 'pipe'):
				pick = pool[gen.randi() % pool.size()]
			if z == 0 and i == 0:
				pick = ['taxi', 4.4]
			last_kind = pick[0]
			var still_chance: float = [0.5 - 0.35 * progress, 0.3 - 0.2 * progress, 0.0][z]
			var moving := z == 2 or (i > 1 and gen.randf() >= still_chance)
			var info := make_platform(pick[0], pick[1], moving, index, platforms)
			var body: StaticBody3D = info['body']
			var motion := parse_motion(pick_motion(gen, z, pick[0], progress, info['long']) if moving else '')
			var rise := snappedf(gen.randf_range(1.2, 1.75 + 0.15 * progress), 0.1)
			if moving and motion['mode'] in ['bob', 'float']:
				rise = minf(rise, 1.6)
			var gap := snappedf(gen.randf_range(0.9, 1.4 + 0.1 * progress), 0.1)
			if pick[0] in ['pipe', 'moto'] or (z == 0 and i == 1):
				rise = minf(rise, 1.3)
				gap = minf(gap, 1.0)
			var cut: float = float(fixes['rise_cut'].get('Platform%02d' % index, 0.0))
			if cut > 0.0:
				rise = maxf(0.5, rise - cut)
				gap = maxf(0.4, gap - cut * 0.6)
			# Mostly one turning direction coils the route upward like a tower.
			var turn := gen.randf_range(14.0, 30.0) if gen.randf() > 0.18 else -gen.randf_range(8.0, 18.0)
			if z == 0 and i < 3:
				# Leave the plaza straight down the north road before coiling.
				turn = 0.0
			var base_heading := heading
			var landing := Vector3.ZERO
			var yaw := 0.0
			var direction := Vector3.ZERO
			# Objects face any way; long ones keep to a few readable angles.
			# Retry other rotations and turns until nothing overlaps.
			for attempt in 12:
				heading = base_heading + deg_to_rad(turn + (attempt / 3) * 18.0 * (1.0 if turn >= 0.0 else -1.0))
				direction = forward_of(heading)
				yaw = heading + (deg_to_rad([0, 90, 30, -30, 60, -60][gen.randi() % 6]) if info['long'] else gen.randf_range(0, TAU))
				if z == 0 and i == 0:
					yaw = heading
				var near: float = extent(previous['info'], previous['yaw'], previous['motion'], direction, true)
				var far: float = extent(info, yaw, motion, -direction, true)
				var near_rest: float = extent(previous['info'], previous['yaw'], previous['motion'], direction, false)
				var far_rest: float = extent(info, yaw, motion, -direction, false)
				# Keep the gap at rest jumpable even when motion sweeps push things apart.
				var swept := (near - near_rest) + (far - far_rest)
				var step_gap := gap
				if step_gap + swept > MAX_REST_GAP:
					step_gap = maxf(0.3, MAX_REST_GAP - swept)
				landing = previous['landing'] + direction * (near + step_gap + far)
				if z == 0 and i == 0:
					landing.y = -bounds_of(body).position.y
				else:
					landing.y = previous['landing'].y + rise
				if (z == 0 and i == 0) or is_clear(landing, info, yaw, motion, [previous]):
					break
				if attempt == 11:
					spine_clashes += 1
			body.position = landing
			body.rotation.y = yaw
			apply_tilt(body, info, pick[0])
			attach_motion(body, motion)
			if i % 8 == 3:
				place_food(body, Vector3(0, 1.15, 0), food_index)
				food_index += 1
			record(body, pick[0], landing.y, maxf(info['sx'], info['sz']) * 0.5, yaw, z, motion_text(motion))
			var here := entry(body, landing, info, yaw, motion, z)
			corridors.append([previous['landing'], landing])
			placed.append(here)
			spine.append(here)
			previous = here
			index += 1
	# Summit pad with the Star of Wishes.
	var made := make_pad('summit', index)
	summit = made[0]
	var summit_direction := forward_of(heading)
	var summit_landing: Vector3 = previous['landing'] + summit_direction * (extent(previous['info'], previous['yaw'], previous['motion'], summit_direction, true) + SUMMIT_GAP + made[1])
	summit_landing.y = previous['landing'].y + SUMMIT_RISE
	summit.position = summit_landing
	summit.rotation.y = heading
	summit.name = 'Summit'
	summit.set_meta('summit', true)
	record(summit, 'summit', summit_landing.y, made[1], heading, ZONES.size() - 1, '')
	var summit_entry := entry(summit, summit_landing, {'sx': made[1] * 2.0, 'sz': made[1] * 2.0, 'height': 1.0, 'long': false}, heading, {}, ZONES.size() - 1)
	corridors.append([previous['landing'], summit_landing])
	placed.append(summit_entry)
	spine.append(summit_entry)
	build_summit(summit)
	var landing_y: float = summit_landing.y
	var side_count := build_side_routes(spine, gen)
	for name in fixes['drop_side']:
		var stone := side_platforms.get_node_or_null(NodePath(name))
		if stone:
			side_platforms.remove_child(stone)
			stone.free()
			side_count -= 1
	print('side rejects ', why, ' / main-path clashes left: ', spine_clashes)
	for item in placed:
		route_points.append(item['landing'])
	food_index += side_foods
	# Scenery that depends on the finished route.
	var route_center := Vector3.ZERO
	for p in route_points:
		route_center += p
	route_center /= route_points.size()
	scatter_clouds(Vector3(route_center.x, 0, route_center.z), zone_heights[1] - 9.0, zone_heights[1] - 4.0, 46, 5.0, 11.0, 1.0, 'CloudSea')
	scatter_clouds(Vector3(route_center.x, 0, route_center.z), zone_heights[1], zone_heights[2] - 4.0, 70, 2.5, 6.0, 0.85, 'CloudPuffs')
	scatter_clouds(Vector3(route_center.x, 0, route_center.z), 12.0, zone_heights[1] - 12.0, 30, 3.0, 7.0, 0.9, 'LowClouds')
	floating_scenery(Vector3(route_center.x, 0, route_center.z), zone_heights)
	space_scenery(Vector3(route_center.x, zone_heights[2], route_center.z), zone_heights[2], landing_y - zone_heights[2])
	level.set_meta('zone_heights', zone_heights)
	level.set_meta('zone_names', zone_names)
	level.set_meta('summit_height', landing_y)
	# Player, light and environment.
	var player = load('res://Scenes/player.tscn').instantiate()
	player.name = 'Player'
	add(player, level)
	player.position = checkpoints.get_child(0).get_node('Spawn').global_position
	var world := WorldEnvironment.new()
	world.name = 'WorldEnvironment'
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.6
	environment.glow_bloom = 0.05
	environment.fog_enabled = true
	environment.fog_density = 0.002
	world.environment = environment
	add(world, level)
	var sun := DirectionalLight3D.new()
	sun.name = 'Sun'
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add(sun, level)
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, 'res://Scenes/world.tscn') == OK)
	var output := FileAccess.open('res://tests/world_layout.json', FileAccess.WRITE)
	output.store_string(JSON.stringify({'zone_heights': zone_heights, 'summit': landing_y, 'platforms': manifest}, '\t'))
	print('Built world: %d platforms + %d side stones, %d checkpoints, %d foods, summit %.1f m, zones at %s' % [platforms.get_child_count(), side_count, checkpoints.get_child_count(), food_index, landing_y, str(zone_heights)])
	level.free()
	quit()

## Side stepping stones around the spine: left, right, behind or diagonal.
## Each one is reachable from its parent and jumps on to a spine step 1-5
## ahead, so there are several ways up and some steps can be skipped.
func build_side_routes(spine: Array, gen: RandomNumberGenerator) -> int:
	var count := 0
	for i in range(0, spine.size() - 3):
		var parent: Dictionary = spine[i]
		if gen.randf() > 0.6:
			continue
		var from := parent
		for depth in 2:
			var made := try_side(spine, from, i, gen, count)
			if made.is_empty():
				break
			count += 1
			from = made
			if gen.randf() > 0.45:
				break
	return count

func try_side(spine: Array, parent: Dictionary, base_index: int, gen: RandomNumberGenerator, count: int) -> Dictionary:
	var z: int = parent['zone']
	var pool: Array = KINDS[z]
	for attempt in 14:
		# Aim at a spine step 1-3 ahead of the branch point and sit to its left or right.
		var link := mini(spine.size() - 1, base_index + 1 + (1 if gen.randf() < 0.35 else 0))
		var target: Dictionary = spine[link]
		if target['body'] == parent['body']:
			continue
		var pick: Array = pool[gen.randi() % pool.size()]
		var moving := z == 2 or gen.randf() < 0.5
		var info := make_platform(pick[0], pick[1], moving, count + 1, side_platforms, 'Side')
		var body: StaticBody3D = info['body']
		var motion := parse_motion(pick_motion(gen, z, pick[0], gen.randf(), info['long']) if moving else '')
		var yaw := gen.randf_range(0, TAU)
		var p_land: Vector3 = parent['landing']
		var t_land: Vector3 = target['landing']
		var base := Vector2(t_land.x - p_land.x, t_land.z - p_land.z)
		var span := base.length()
		var radius := sweep_radius(info, yaw, motion)
		var p_flat := Vector2(p_land.x, p_land.z)
		var t_flat := Vector2(t_land.x, t_land.z)
		var want_in := gen.randf_range(0.6, 1.1)
		var want_out := gen.randf_range(0.6, 1.0)
		var r1 := sweep_radius(parent['info'], parent['yaw'], parent['motion']) + want_in + radius
		var r2 := sweep_radius(target['info'], target['yaw'], target['motion']) + want_out + radius
		var side := 1.0 if gen.randf() < 0.5 else -1.0
		var flat := Vector2.INF
		var placed_ok := false
		var landing := Vector3.ZERO
		# Intersection of two jump-range circles (left or right of the line),
		# refined so the swept edge gaps match the wanted gaps along each jump.
		for iteration in 6:
			if span < 0.5 or span >= r1 + r2 or span <= absf(r1 - r2):
				flat = Vector2.INF
				break
			var along := (r1 * r1 - r2 * r2 + span * span) / (2.0 * span)
			var across := sqrt(maxf(0.0, r1 * r1 - along * along))
			var unit := base / span
			flat = p_flat + unit * along + Vector2(-unit.y, unit.x) * across * side
			var d_in := Vector3(flat.x - p_flat.x, 0, flat.y - p_flat.y)
			var d_out := Vector3(t_flat.x - flat.x, 0, t_flat.y - flat.y)
			var got_in: float = d_in.length() - extent(parent['info'], parent['yaw'], parent['motion'], d_in.normalized(), true) - extent(info, yaw, motion, -d_in.normalized(), true)
			var got_out: float = d_out.length() - extent(info, yaw, motion, d_out.normalized(), true) - extent(target['info'], target['yaw'], target['motion'], -d_out.normalized(), true)
			r1 += want_in - got_in
			r2 += want_out - got_out
		if flat != Vector2.INF:
			var low: float = p_land.y + 0.3
			var high: float = minf(p_land.y + 1.5, t_land.y + 3.0)
			if motion.get('mode', '') in ['bob', 'float']:
				high = minf(high, p_land.y + 1.3)
			if high > low:
				landing = Vector3(flat.x, gen.randf_range(low, high), flat.y)
				landing.y = maxf(landing.y, t_land.y - 1.5)
				var candidate := entry(body, landing, info, yaw, motion, z)
				var gap_in := rest_gap(parent, candidate)
				var gap_out := rest_gap(candidate, target)
				var rise_out: float = t_land.y - landing.y
				if not (gap_in >= 0.4 and gap_in <= MAX_REST_GAP): note('gap_in %.0f' % gap_in)
				elif not (gap_out >= 0.4 and gap_out <= 1.9): note('gap_out %.0f' % gap_out)
				elif not (rise_out <= 1.6 and landing.y - p_land.y <= 1.6): note('rise')
				elif not is_clear(landing, info, yaw, motion, [parent, target]): note('clear')
				elif not corridor_clear(parent, candidate): note('corr_in')
				elif not corridor_clear(candidate, target): note('corr_out')
				else: placed_ok = true
			else: note('height')
		else: note('circles')
		if not placed_ok:
			body.get_parent().remove_child(body)
			body.free()
			continue
		body.position = landing
		body.rotation.y = yaw
		apply_tilt(body, info, pick[0])
		attach_motion(body, motion)
		body.set_meta('landing', landing)
		body.set_meta('half_depth', maxf(info['sx'], info['sz']) * 0.5)
		body.set_meta('zone', z)
		body.set_meta('kind', pick[0])
		body.set_meta('parent', level.get_path_to(parent['body']))
		body.set_meta('link', level.get_path_to(target['body']))
		body.set_meta('skips', link - base_index - 1)
		if gen.randf() < 0.35:
			place_food(body, Vector3(0, 1.15, 0), 100 + side_foods)
			side_foods += 1
		var made := entry(body, landing, info, yaw, motion, z)
		corridors.append([p_land, landing])
		corridors.append([landing, t_land])
		placed.append(made)
		return made
	return {}

func record(body: Node3D, kind: String, landing: float, half_depth: float, heading: float, zone: int, motion: String) -> void:
	body.set_meta('landing', Vector3(body.position.x, landing, body.position.z))
	body.set_meta('half_depth', half_depth)
	body.set_meta('zone', zone)
	body.set_meta('kind', kind)
	manifest.append({'name': str(body.name), 'kind': kind, 'zone': zone, 'motion': motion,
		'landing': [snappedf(body.position.x, 0.01), snappedf(landing, 0.01), snappedf(body.position.z, 0.01)],
		'half_depth': snappedf(half_depth, 0.01), 'heading_deg': snappedf(rad_to_deg(heading), 0.1)})
