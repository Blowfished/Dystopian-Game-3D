class_name Palette
extends RefCounted

## Centralized Cozy Cyberpunk color palette and cached stylized material builders.
## Deep indigo-violet rainy night, rich warm amber light pools against violet-indigo shadows,
## with vivid magenta, cyan, and teal neon accents.

# --- Night Sky & Atmospheric Haze (Deep Indigo-Violet) ---
const SKY_ZENITH := Color("#0C091F")
const SKY_MID := Color("#191336")
const SKY_HORIZON := Color("#2B2152")
const FOG_INDIGO := Color("#20183D")
const VOLUMETRIC_FOG := Color("#271E4A")
const AMBIENT_INDIGO := Color("#2F2654")
const MOON_VIOLET := Color("#A89CE6")

# --- Architecture & Structural Materials ---
const WALKWAY_STONE := Color("#1F1C36")
const WALKWAY_GROUT := Color("#131024")
const STEEL_DARK := Color("#211E38")
const STEEL_MID := Color("#302C4F")
const STEEL_LIGHT := Color("#46416E")
const CONCRETE_WARM := Color("#352E4A")
const CONCRETE_DARK := Color("#221E36")
const FACADE_WALL := Color("#241F3B")
const FACADE_TRIM := Color("#3A335C")
const WOOD_WARM := Color("#694432")
const WOOD_DARK := Color("#422A22")

# --- Warm Cozy Light Pools ---
const LANTERN_AMBER := Color("#FFB652")
const LANTERN_GLOW := Color("#FFD082")
const STALL_WARM := Color("#FFD891")
const LAMP_AMBER := Color("#FFAC4D")
const CREAM_WARM := Color("#F7E9CF")
const WINDOW_WARM_A := Color("#FFC26B")
const WINDOW_WARM_B := Color("#FFE6B3")
const WINDOW_COOL := Color("#78CCE0")

# --- Cyberpunk Accents ---
const LANDMARK_TEAL := Color("#24E5D0")
const LANDMARK_TEAL_DEEP := Color("#126E78")
const BEACON_MAGENTA := Color("#FF3FA4")
const NEON_CORAL := Color("#FF6B6B")
const NEON_CYAN := Color("#36F0FF")
const NEON_VIOLET := Color("#B36BFF")
const AWNING_STRIPE_A := Color("#C95540")
const AWNING_STRIPE_B := Color("#F2E4CC")
const CANOPY_OCHRE := Color("#E09B3E")
const CANOPY_SAGE := Color("#3F8070")
const CANOPY_TEAL := Color("#2C7280")
const CONE_ORANGE := Color("#E86E38")
const CONE_STRIPE := Color("#F2ECE1")
const FOLIAGE_DARK := Color("#244A47")
const FOLIAGE_MID := Color("#366B62")
const FOLIAGE_LIGHT := Color("#4D8C7A")
const FLOWER_CORAL := Color("#F57A7A")
const FLOWER_GOLD := Color("#FFD46B")
const FLOWER_LAVENDER := Color("#C099F7")
const GREENHOUSE_GLOW := Color("#A8F0C6")
const SCOOTER_BODY := Color("#3F8A8C")
const SCOOTER_ACCENT := Color("#EBAA4E")
const CRATE_TEAL := Color("#325D6B")
const CRATE_OCHRE := Color("#91653A")

# --- Courier Character ---
const COURIER_JACKET := Color("#D99438")
const COURIER_JACKET_SHADOW := Color("#9E6224")
const COURIER_SCARF := Color("#C95042")
const COURIER_PANTS := Color("#1D253D")
const COURIER_BOOTS := Color("#2F2526")
const COURIER_BAG := Color("#6E442B")
const COURIER_SKIN := Color("#E8C4A8")
const COURIER_HAT := Color("#293859")
const COURIER_TAG_TEAL := Color("#3BF0DA")

const STYLIZED_SHADER: Shader = preload("res://shaders/stylized_prop.gdshader")

static var _stylized_cache: Dictionary = {}
static var _emissive_cache: Dictionary = {}
static var _flat_cache: Dictionary = {}
static var _glow_pool_tex: ImageTexture = null


static func get_stylized_shader() -> Shader:
	return STYLIZED_SHADER


static func make_stylized_material(
	base_color: Color,
	roughness: float = 0.78,
	metallic: float = 0.05,
	rim_color: Color = Color("#7E6EC4"),
	rim_strength: float = 0.24,
	emission_color: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> ShaderMaterial:
	var key := "%s|%.2f|%.2f|%s|%.2f|%s|%.2f" % [
		base_color.to_html(), roughness, metallic, rim_color.to_html(), rim_strength, emission_color.to_html(), emission_energy
	]
	if _stylized_cache.has(key):
		return _stylized_cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = get_stylized_shader()
	mat.set_shader_parameter("albedo_color", base_color)
	mat.set_shader_parameter("shadow_tint", Color("#221840"))
	mat.set_shader_parameter("roughness_val", roughness)
	mat.set_shader_parameter("metallic_val", metallic)
	mat.set_shader_parameter("rim_color", rim_color)
	mat.set_shader_parameter("rim_strength", rim_strength)
	mat.set_shader_parameter("rim_power", 3.0)
	mat.set_shader_parameter("emission_color", emission_color)
	mat.set_shader_parameter("emission_energy", emission_energy)
	_stylized_cache[key] = mat
	return mat


static func make_emissive_material(
	color: Color,
	energy: float = 2.4,
	roughness: float = 0.35
) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [color.to_html(), energy, roughness]
	if _emissive_cache.has(key):
		return _emissive_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_emissive_cache[key] = mat
	return mat


static func make_flat_material(
	color: Color,
	roughness: float = 0.75,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [color.to_html(), roughness, metallic]
	if _flat_cache.has(key):
		return _flat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.rim_enabled = true
	mat.rim = 0.24
	mat.rim_tint = 0.55
	_flat_cache[key] = mat
	return mat


static func get_soft_glow_texture() -> ImageTexture:
	if _glow_pool_tex != null:
		return _glow_pool_tex
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center := Vector2(sz * 0.5, sz * 0.5)
	for y in range(sz):
		for x in range(sz):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / (sz * 0.5)
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.2)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_glow_pool_tex = ImageTexture.create_from_image(img)
	return _glow_pool_tex


static func make_additive_glow_material(color: Color, alpha: float = 0.34) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.albedo_texture = get_soft_glow_texture()
	return mat
