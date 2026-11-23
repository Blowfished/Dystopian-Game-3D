class_name Palette
extends RefCounted

## Centralized Cozy Cyberpunk color palette and stylized material builders.
## Deep navy/indigo night, warm amber light pools against cool blue shadows,
## with restrained teal and magenta accents.

# --- Night Sky & Atmospheric Haze ---
const SKY_ZENITH := Color("#070B1A")
const SKY_MID := Color("#121936")
const SKY_HORIZON := Color("#232B4F")
const FOG_INDIGO := Color("#171E3B")
const VOLUMETRIC_FOG := Color("#1B2342")
const AMBIENT_INDIGO := Color("#1F2B52")
const MOON_BLUE := Color("#8BA8E8")

# --- Architecture & Structural Materials ---
const WALKWAY_STONE := Color("#1B2238")
const WALKWAY_GROUT := Color("#111627")
const STEEL_DARK := Color("#1E263D")
const STEEL_MID := Color("#2C3757")
const STEEL_LIGHT := Color("#3D4B73")
const CONCRETE_WARM := Color("#2D3347")
const CONCRETE_DARK := Color("#1D2234")
const FACADE_WALL := Color("#202842")
const FACADE_TRIM := Color("#323E61")
const WOOD_WARM := Color("#5A3B2E")
const WOOD_DARK := Color("#3A2620")

# --- Warm Cozy Light Pools ---
const LANTERN_AMBER := Color("#FFB454")
const LANTERN_GLOW := Color("#FFCC7A")
const STALL_WARM := Color("#FFD48C")
const LAMP_AMBER := Color("#FFA94D")
const CREAM_WARM := Color("#F5E6CC")
const WINDOW_WARM_A := Color("#FFBE66")
const WINDOW_WARM_B := Color("#FFE2A8")
const WINDOW_COOL := Color("#76C7D6")

# --- Restrained Cyberpunk Accents ---
const LANDMARK_TEAL := Color("#24E5D0")
const LANDMARK_TEAL_DEEP := Color("#126E78")
const BEACON_MAGENTA := Color("#FF3FA4")
const NEON_CORAL := Color("#FF6B6B")
const AWNING_STRIPE_A := Color("#C2523E")
const AWNING_STRIPE_B := Color("#EFE0C6")
const CONE_ORANGE := Color("#E56B38")
const CONE_STRIPE := Color("#F2ECE1")
const FOLIAGE_DARK := Color("#244A47")
const FOLIAGE_MID := Color("#366B62")
const FOLIAGE_LIGHT := Color("#4D8C7A")
const SCOOTER_BODY := Color("#3F8A8C")
const SCOOTER_ACCENT := Color("#E8A44A")
const CRATE_TEAL := Color("#315B66")
const CRATE_OCHRE := Color("#8C6239")

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


static func get_stylized_shader() -> Shader:
	return STYLIZED_SHADER


static func make_stylized_material(
	base_color: Color,
	roughness: float = 0.78,
	metallic: float = 0.05,
	rim_color: Color = Color("#5E83C4"),
	rim_strength: float = 0.22,
	emission_color: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = get_stylized_shader()
	mat.set_shader_parameter("albedo_color", base_color)
	mat.set_shader_parameter("shadow_tint", Color("#162044"))
	mat.set_shader_parameter("roughness_val", roughness)
	mat.set_shader_parameter("metallic_val", metallic)
	mat.set_shader_parameter("rim_color", rim_color)
	mat.set_shader_parameter("rim_strength", rim_strength)
	mat.set_shader_parameter("rim_power", 3.2)
	mat.set_shader_parameter("emission_color", emission_color)
	mat.set_shader_parameter("emission_energy", emission_energy)
	return mat


static func make_emissive_material(
	color: Color,
	energy: float = 2.4,
	roughness: float = 0.35
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat


static func make_flat_material(
	color: Color,
	roughness: float = 0.75,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.rim_enabled = true
	mat.rim = 0.22
	mat.rim_tint = 0.55
	return mat
