"""Exports the front frame of crt_terminal_room.blend for the game. Run with Blender 5.2:

    blender -b crt_terminal_room.blend --python tools/blender/export_front.py -- --out <dir> [--preview]

Writes under <dir>, laid out like the repository:
    assets/front/<group>.exr          room light groups, linear, half float, ZIP
    assets/front/mug_<group>.exr      the mug's light groups, premultiplied, cropped to the mug
    assets/front/mug_alpha.exr        the mug's coverage, in every channel, same crop
    assets/front/glass_uv.exr         (u*m, v*m, m): ND-OS position on the glass (top-left origin)
                                      times glass coverage m, 32-bit float
    assets/front/agx_punchy_65.bin    the scene's view transform and look baked into a 3D LUT
    assets/front/manifest.tres        sizes, mug position and exposure, read by the game
    tests/reference/front_<state>.png the exported files summed back into a frame and run through the
                                      scene's view transform; the game's frame must match them

--preview renders at 25% with 32 samples for a quick look before the full export.
The .blend file is never saved.
"""

import argparse
import datetime
import os
import shutil
import sys
import tempfile

import bpy
import numpy as np

GROUPS = ("lamp", "screen", "base", "world", "indicator")
MAIN_LAYER = "ViewLayer"
MUG_LAYER = "Mug"
GLASS_OBJECT = "CRT_Glass"
GLASS_MATERIAL = "PC_Glass"
GLASS_UV_MAP = "UV_Flat"
UV_AOV = "ndos_uv"

# The player sees the frame without its 5% margin on each side; the margin is room for camera sway.
VIEW_SHARE = 1.0 / 1.1
# Foreground defocus of the mug at 100% resolution, as in the approved look.
MUG_BLUR_PX = 13
# Extra pixels around the mug's coverage, so the blur's faint tail is not cut.
MUG_PAD_PX = 8
# Coverage below this counts as empty when cropping the mug.
MUG_EMPTY = 0.5 / 255.0
PREVIEW_PERCENT = 25
PREVIEW_SAMPLES = 32
# The glass UV pass needs only camera hits; this many samples give smooth edge coverage.
UV_SAMPLES = 64

LUT_SIZE = 65
# log2 range of the LUT shaper, the same as Blender's AgX input range.
LUT_LO, LUT_HI = -12.47393, 12.5260688117
LUT_FILE = "agx_punchy_65.bin"

# Light strengths of the reference states, as in game/front/presets.
STATES = {
	"normal": {group: 1.0 for group in GROUPS},
	"lamp_off": {group: (0.0 if group == "lamp" else 1.0) for group in GROUPS},
}


def main() -> None:
	args = parse_args()
	scene = bpy.context.scene
	problems = check_scene(scene)
	if problems:
		fail("The scene does not match what the export expects:\n  " + "\n  ".join(problems))

	if args.preview:
		scene.render.resolution_percentage = PREVIEW_PERCENT
		scene.cycles.samples = PREVIEW_SAMPLES
	percent = scene.render.resolution_percentage
	frame_size = (scene.render.resolution_x * percent // 100, scene.render.resolution_y * percent // 100)
	view_size = (round(frame_size[0] * VIEW_SHARE), round(frame_size[1] * VIEW_SHARE))
	if (frame_size[0] - view_size[0]) % 2 or (frame_size[1] - view_size[1]) % 2:
		fail(f"Frame {frame_size} and view {view_size} leave an uneven margin")

	assets = os.path.join(args.out, "assets", "front")
	references = os.path.join(args.out, "tests", "reference")
	os.makedirs(assets, exist_ok=True)
	os.makedirs(references, exist_ok=True)
	raw = tempfile.mkdtemp(prefix="export_front_")
	try:
		scene.render.use_compositing = True
		render_layers(scene, raw, percent / 100.0)
		uv_range = render_glass_uv(scene, raw)
		mug_rect = write_layers(scene, raw, assets)
	finally:
		shutil.rmtree(raw, ignore_errors=True)

	ndos_visible = write_glass_uv_report(assets)
	for state, strengths in STATES.items():
		write_reference(scene, assets, mug_rect, strengths, view_size, os.path.join(references, f"front_{state}.png"))
	bake_lut(scene, os.path.join(assets, LUT_FILE))
	write_manifest(os.path.join(assets, "manifest.tres"), frame_size, view_size, mug_rect, ndos_visible,
		scene, args.preview)
	log(f"Glass UV map {GLASS_UV_MAP} spans u {uv_range[0]:.4f}..{uv_range[1]:.4f}, v {uv_range[2]:.4f}..{uv_range[3]:.4f}")
	log(f"Done: {args.out}")


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(prog="export_front.py")
	parser.add_argument("--out", required=True, help="folder to write into, laid out like the repository")
	parser.add_argument("--preview", action="store_true", help="25%% size, 32 samples")
	return parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])


def log(message: str) -> None:
	print(f"[export_front] {message}", flush=True)


def fail(message: str) -> None:
	print(f"[export_front] FAILED: {message}", file=sys.stderr, flush=True)
	sys.exit(1)


def check_scene(scene: bpy.types.Scene) -> list:
	problems = []
	if scene.render.engine != "CYCLES":
		problems.append(f"render engine is {scene.render.engine}, not CYCLES")
	view = scene.view_settings
	if view.view_transform != "AgX" or view.look != "AgX - Punchy" or view.gamma != 1.0 or view.use_curve_mapping:
		problems.append("colour management must be AgX with the 'AgX - Punchy' look, gamma 1, no curves")
	if scene.display_settings.display_device != "sRGB":
		problems.append("display device must be sRGB")
	if not scene.render.film_transparent:
		problems.append("film must be transparent, the mug layer needs alpha")
	for name in (MAIN_LAYER, MUG_LAYER):
		layer = scene.view_layers.get(name)
		if layer is None:
			problems.append(f"view layer {name} is missing")
			continue
		missing = [group for group in GROUPS if group not in layer.lightgroups]
		if missing:
			problems.append(f"view layer {name} has no light groups {missing}")
		if not layer.cycles.denoising_store_passes:
			problems.append(f"view layer {name} does not store denoising data")
	glass = bpy.data.objects.get(GLASS_OBJECT)
	if glass is None or glass.type != "MESH":
		problems.append(f"mesh object {GLASS_OBJECT} is missing")
	elif GLASS_UV_MAP not in glass.data.uv_layers:
		problems.append(f"{GLASS_OBJECT} has no UV map {GLASS_UV_MAP}")
	if bpy.data.materials.get(GLASS_MATERIAL) is None:
		problems.append(f"material {GLASS_MATERIAL} is missing")
	else:
		# The UV AOV goes into this material, so any other object with it would write a wrong UV.
		users = [o.name for o in bpy.data.objects if o.type == "MESH"
			and any(slot.material and slot.material.name == GLASS_MATERIAL for slot in o.material_slots)]
		if users != [GLASS_OBJECT]:
			problems.append(f"material {GLASS_MATERIAL} must be used by {GLASS_OBJECT} only, not {users}")
	return problems


def add_glass_uv_aov(scene: bpy.types.Scene) -> tuple:
	"""Makes the glass write its ND-OS position into an AOV: u right, v down, from 0 to 1 over the mesh."""
	glass = bpy.data.objects[GLASS_OBJECT]
	mesh = glass.data
	uv_layer = mesh.uv_layers[GLASS_UV_MAP]
	uvs = np.empty(len(uv_layer.data) * 2, np.float32)
	uv_layer.data.foreach_get("uv", uvs)
	uvs = uvs.reshape(-1, 2)
	u_min, v_min = uvs.min(0)
	u_max, v_max = uvs.max(0)
	check_uv_orientation(glass, uv_layer)

	layer = scene.view_layers[MAIN_LAYER]
	if UV_AOV not in layer.aovs:
		aov = layer.aovs.add()
		aov.name = UV_AOV
		aov.type = "COLOR"

	tree = bpy.data.materials[GLASS_MATERIAL].node_tree
	uv = tree.nodes.new("ShaderNodeUVMap")
	uv.uv_map = GLASS_UV_MAP
	split = tree.nodes.new("ShaderNodeSeparateXYZ")
	tree.links.new(uv.outputs["UV"], split.inputs[0])
	u = map_range(tree, split.outputs["X"], u_min, u_max, 0.0, 1.0)
	v = map_range(tree, split.outputs["Y"], v_min, v_max, 1.0, 0.0)
	join = tree.nodes.new("ShaderNodeCombineXYZ")
	tree.links.new(u, join.inputs["X"])
	tree.links.new(v, join.inputs["Y"])
	# Constant 1 on the glass; after pixel filtering it becomes the glass coverage m.
	join.inputs["Z"].default_value = 1.0
	output = tree.nodes.new("ShaderNodeOutputAOV")
	output.aov_name = UV_AOV
	tree.links.new(join.outputs[0], output.inputs["Color"])
	return float(u_min), float(u_max), float(v_min), float(v_max)


def map_range(tree, socket, from_min: float, from_max: float, to_min: float, to_max: float):
	node = tree.nodes.new("ShaderNodeMapRange")
	node.clamp = False
	node.inputs["From Min"].default_value = from_min
	node.inputs["From Max"].default_value = from_max
	node.inputs["To Min"].default_value = to_min
	node.inputs["To Max"].default_value = to_max
	tree.links.new(socket, node.inputs["Value"])
	return node.outputs["Result"]


def check_uv_orientation(glass: bpy.types.Object, uv_layer) -> None:
	"""The glass faces the camera, so screen left is -X and up is +Z; UV u must grow right, v up."""
	mesh = glass.data
	world = glass.matrix_world
	positions = [world @ vertex.co for vertex in mesh.vertices]
	uv_at = {}
	for loop in mesh.loops:
		uv_at[loop.vertex_index] = uv_layer.data[loop.index].uv
	top_left = min(range(len(positions)), key=lambda i: positions[i].x - positions[i].z)
	bottom_right = min(range(len(positions)), key=lambda i: -positions[i].x + positions[i].z)
	a, b = uv_at[top_left], uv_at[bottom_right]
	if not (a.x < b.x and a.y > b.y):
		fail(f"{GLASS_UV_MAP} is not oriented u right, v up: top-left {tuple(a)}, bottom-right {tuple(b)}")


def render_layers(scene: bpy.types.Scene, raw: str, scale: float) -> None:
	"""Renders both view layers with the scene's own settings and writes every light group pass."""
	tree, files = new_compositor(scene, raw)
	main = render_layer(tree, scene, MAIN_LAYER)
	mug = render_layer(tree, scene, MUG_LAYER)
	tree.links.new(main.outputs["Image"], tree.nodes["Group Output"].inputs[0])
	for group in GROUPS:
		write_pass(tree, files, denoise(tree, main, group), f"main_{group}")
		write_pass(tree, files, blur(tree, denoise(tree, mug, group), MUG_BLUR_PX * scale), f"mug_{group}")
	write_pass(tree, files, blur(tree, mug.outputs["Alpha"], MUG_BLUR_PX * scale), "mug_alpha")
	log(f"Rendering the light layers, {scene.cycles.samples} samples")
	bpy.ops.render.render(write_still=False)


def render_glass_uv(scene: bpy.types.Scene, raw: str) -> tuple:
	"""A second, quick render of the glass UV pass alone. Volumes are hidden: the camera sits inside the
	room haze, which scatters part of the rays before they reach the glass, and then the pass would no
	longer hold the glass coverage. Returns the UV map's range."""
	uv_range = add_glass_uv_aov(scene)
	log(f"Hidden for the glass UV pass: {hide_volumes(scene) or 'nothing'}")
	scene.view_layers[MUG_LAYER].use = False
	scene.cycles.samples = UV_SAMPLES
	scene.cycles.use_adaptive_sampling = False
	scene.cycles.max_bounces = 0
	tree, files = new_compositor(scene, raw)
	layer = render_layer(tree, scene, MAIN_LAYER)
	tree.links.new(layer.outputs["Image"], tree.nodes["Group Output"].inputs[0])
	write_pass(tree, files, layer.outputs[UV_AOV], "glass_uv")
	log(f"Rendering the glass UV pass, {UV_SAMPLES} samples")
	bpy.ops.render.render(write_still=False)
	return uv_range


def hide_volumes(scene: bpy.types.Scene) -> list:
	"""Hides from render every object that is only a volume, and the world's volume. Returns their names."""
	hidden = []
	for obj in scene.objects:
		if not obj.hide_render and (obj.type == "VOLUME" or (obj.type == "MESH" and is_volume_only(obj))):
			obj.hide_render = True
			hidden.append(obj.name)
	if scene.world and scene.world.node_tree:
		output = scene.world.node_tree.get_output_node("CYCLES")
		if output and output.inputs["Volume"].is_linked:
			for link in list(output.inputs["Volume"].links):
				scene.world.node_tree.links.remove(link)
			hidden.append(f"world {scene.world.name}")
	return hidden


def is_volume_only(obj: bpy.types.Object) -> bool:
	materials = [slot.material for slot in obj.material_slots if slot.material]
	if not materials:
		return False
	for material in materials:
		output = material.node_tree.get_output_node("CYCLES") if material.node_tree else None
		if output is None or output.inputs["Surface"].is_linked or not output.inputs["Volume"].is_linked:
			return False
	return True


def new_compositor(scene: bpy.types.Scene, raw: str) -> tuple:
	"""A fresh compositor tree, in use from now on, with a node that writes 32-bit EXRs into raw. The
	scene's own tree is left alone and nothing is saved."""
	tree = bpy.data.node_groups.new("export_front", "CompositorNodeTree")
	tree.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
	tree.nodes.new("NodeGroupOutput")
	scene.compositing_node_group = tree
	files = tree.nodes.new("CompositorNodeOutputFile")
	files.directory = raw
	files.file_name = ""
	files.format.media_type = "IMAGE"
	files.format.file_format = "OPEN_EXR"
	files.format.color_depth = "32"
	files.format.color_mode = "RGBA"
	files.format.exr_codec = "ZIP"
	return tree, files


def write_pass(tree, files, socket, name: str) -> None:
	files.file_output_items.new("RGBA", name)
	tree.links.new(socket, files.inputs[name])


def render_layer(tree, scene: bpy.types.Scene, name: str):
	node = tree.nodes.new("CompositorNodeRLayers")
	node.scene = scene
	node.layer = name
	return node


def denoise(tree, layer_node, group: str):
	node = tree.nodes.new("CompositorNodeDenoise")
	node.inputs["HDR"].default_value = True
	node.inputs["Prefilter"].default_value = "Accurate"
	node.inputs["Quality"].default_value = "Follow Scene"
	tree.links.new(layer_node.outputs[f"Combined_{group}"], node.inputs["Image"])
	tree.links.new(layer_node.outputs["Denoising Albedo"], node.inputs["Albedo"])
	tree.links.new(layer_node.outputs["Denoising Normal"], node.inputs["Normal"])
	return node.outputs["Image"]


def blur(tree, socket, size: float):
	node = tree.nodes.new("CompositorNodeBlur")
	node.inputs["Size"].default_value = (size, size)
	node.inputs["Type"].default_value = "Gaussian"
	tree.links.new(socket, node.inputs["Image"])
	return node.outputs["Image"]


def read_exr(path: str) -> np.ndarray:
	"""Pixels as float32 [row][column][RGBA], row 0 at the top."""
	image = bpy.data.images.load(path)
	image.colorspace_settings.name = "Non-Color"
	width, height = image.size
	pixels = np.empty(width * height * 4, np.float32)
	image.pixels.foreach_get(pixels)
	bpy.data.images.remove(image)
	return np.flipud(pixels.reshape(height, width, 4))


def write_exr(scene: bpy.types.Scene, pixels: np.ndarray, path: str, depth: str) -> None:
	"""Writes [row][column][RGB] or [RGBA] pixels, row 0 at the top, as linear RGB EXR with ZIP."""
	height, width = pixels.shape[:2]
	rgba = np.ones((height, width, 4), np.float32)
	rgba[..., :pixels.shape[2]] = pixels
	image = bpy.data.images.new(os.path.basename(path), width, height, alpha=True, float_buffer=True)
	image.colorspace_settings.name = "Non-Color"
	image.pixels.foreach_set(np.flipud(rgba).ravel())
	settings = scene.render.image_settings
	settings.media_type = "IMAGE"
	settings.file_format = "OPEN_EXR"
	settings.color_depth = depth
	settings.color_mode = "RGB"
	settings.exr_codec = "ZIP"
	image.save_render(path, scene=scene)
	bpy.data.images.remove(image)


def raw_file(raw: str, name: str) -> str:
	matches = sorted(file for file in os.listdir(raw) if file.startswith(name) and file.endswith(".exr"))
	if not matches:
		fail(f"the render wrote no {name} pass into {raw}")
	return os.path.join(raw, matches[0])


def write_layers(scene: bpy.types.Scene, raw: str, assets: str) -> tuple:
	"""Writes the final files and returns the mug crop as (x, y, width, height), top-left origin."""
	for group in GROUPS:
		write_exr(scene, read_exr(raw_file(raw, f"main_{group}"))[..., :3], os.path.join(assets, f"{group}.exr"), "16")

	alpha = read_exr(raw_file(raw, "mug_alpha"))[..., 0]
	mug_rect = mug_crop(alpha)
	x, y, width, height = mug_rect
	crop = (slice(y, y + height), slice(x, x + width))
	write_exr(scene, np.repeat(alpha[crop][..., None], 3, 2), os.path.join(assets, "mug_alpha.exr"), "16")
	for group in GROUPS:
		mug = read_exr(raw_file(raw, f"mug_{group}"))[..., :3]
		write_exr(scene, mug[crop], os.path.join(assets, f"mug_{group}.exr"), "16")

	write_exr(scene, read_exr(raw_file(raw, "glass_uv"))[..., :3], os.path.join(assets, "glass_uv.exr"), "32")
	return mug_rect


def mug_crop(alpha: np.ndarray) -> tuple:
	"""Smallest rectangle around the mug plus padding, in whole 4x4 blocks for texture compression."""
	rows = np.flatnonzero((alpha > MUG_EMPTY).any(1))
	columns = np.flatnonzero((alpha > MUG_EMPTY).any(0))
	if rows.size == 0:
		fail("the mug layer is empty")
	height, width = alpha.shape
	left = max(0, (columns[0] - MUG_PAD_PX) // 4 * 4)
	top = max(0, (rows[0] - MUG_PAD_PX) // 4 * 4)
	right = min(width, -(-(columns[-1] + 1 + MUG_PAD_PX) // 4) * 4)
	bottom = min(height, -(-(rows[-1] + 1 + MUG_PAD_PX) // 4) * 4)
	return int(left), int(top), int(right - left), int(bottom - top)


def write_glass_uv_report(assets: str) -> tuple:
	"""Part of ND-OS seen through the glass, as (u, v, width, height); the rest hides under the bezel."""
	uv = read_exr(os.path.join(assets, "glass_uv.exr"))
	inside = uv[..., 2] > 0.999
	if not inside.any():
		fail("the glass UV pass is empty")
	u = uv[..., 0][inside] / uv[..., 2][inside]
	v = uv[..., 1][inside] / uv[..., 2][inside]
	visible = (float(u.min()), float(v.min()), float(u.max() - u.min()), float(v.max() - v.min()))
	log("ND-OS visible through the glass: u %.4f..%.4f, v %.4f..%.4f" % (u.min(), u.max(), v.min(), v.max()))
	return visible


def write_reference(scene, assets: str, mug_rect: tuple, strengths: dict, view_size: tuple, path: str) -> None:
	"""The frame the game must show for these light strengths, built from the files just written."""
	room = sum(read_exr(os.path.join(assets, f"{group}.exr"))[..., :3] * strengths[group] for group in GROUPS)
	x, y, width, height = mug_rect
	mug = sum(read_exr(os.path.join(assets, f"mug_{group}.exr"))[..., :3] * strengths[group] for group in GROUPS)
	alpha = read_exr(os.path.join(assets, "mug_alpha.exr"))[..., :1]
	area = room[y:y + height, x:x + width]
	room[y:y + height, x:x + width] = area * (1.0 - alpha) + mug
	frame_height, frame_width = room.shape[:2]
	left = (frame_width - view_size[0]) // 2
	top = (frame_height - view_size[1]) // 2
	view = room[top:top + view_size[1], left:left + view_size[0]]
	save_display_png(scene, view, path)


def save_display_png(scene: bpy.types.Scene, linear: np.ndarray, path: str) -> None:
	"""Saves linear pixels (row 0 at the top) through the scene's view transform, look and exposure."""
	height, width = linear.shape[:2]
	rgba = np.ones((height, width, 4), np.float32)
	rgba[..., :3] = linear
	image = bpy.data.images.new(os.path.basename(path), width, height, alpha=True, float_buffer=True)
	image.colorspace_settings.name = "Linear Rec.709"
	image.pixels.foreach_set(np.flipud(rgba).ravel())
	settings = scene.render.image_settings
	settings.media_type = "IMAGE"
	settings.file_format = "PNG"
	settings.color_depth = "8"
	settings.color_mode = "RGB"
	image.save_render(path, scene=scene)
	bpy.data.images.remove(image)


def bake_lut(scene: bpy.types.Scene, path: str) -> None:
	"""Bakes the view transform and look (without exposure, which the game applies) into a LUT file:
	int32 size, float32 log2 low and high, then float32 RGB for every [b][g][r]."""
	exposure = scene.view_settings.exposure
	scene.view_settings.exposure = 0.0
	steps = np.exp2(LUT_LO + np.linspace(0.0, 1.0, LUT_SIZE, dtype=np.float32) * (LUT_HI - LUT_LO))
	n = LUT_SIZE
	# One image: x = r + b * n, y = g.
	grid = np.stack([
		np.tile(steps, n)[None, :].repeat(n, 0),
		steps[:, None].repeat(n * n, 1),
		np.repeat(steps, n)[None, :].repeat(n, 0),
	], -1)
	display = through_view_transform(scene, grid)
	lut = np.stack([display[:, b * n:(b + 1) * n, :] for b in range(n)])
	with open(path, "wb") as file:
		file.write(np.array([n], np.int32).tobytes())
		file.write(np.array([LUT_LO, LUT_HI], np.float32).tobytes())
		file.write(lut.astype(np.float32).tobytes())

	rng = np.random.default_rng(1)
	test = np.exp2(rng.uniform(-10.0, 6.0, (128, 128, 3))).astype(np.float32)
	error = np.abs(apply_lut(lut, test) - through_view_transform(scene, test)) * 255.0
	scene.view_settings.exposure = exposure
	log(f"LUT against Blender on random colours: mean {error.mean():.3f}, max {error.max():.3f} steps of 255")
	if error.mean() > 0.5:
		fail("the baked LUT does not match Blender's view transform")


def through_view_transform(scene: bpy.types.Scene, linear: np.ndarray) -> np.ndarray:
	"""Display values (0..1) Blender gives for linear pixels; rows are kept in array order."""
	directory = tempfile.mkdtemp(prefix="export_front_lut_")
	try:
		path = os.path.join(directory, "lut.png")
		height, width = linear.shape[:2]
		rgba = np.ones((height, width, 4), np.float32)
		rgba[..., :3] = linear
		image = bpy.data.images.new("lut", width, height, alpha=True, float_buffer=True)
		image.colorspace_settings.name = "Linear Rec.709"
		image.pixels.foreach_set(rgba.ravel())
		settings = scene.render.image_settings
		settings.media_type = "IMAGE"
		settings.file_format = "PNG"
		settings.color_depth = "16"
		settings.color_mode = "RGB"
		image.save_render(path, scene=scene)
		bpy.data.images.remove(image)
		back = bpy.data.images.load(path)
		back.colorspace_settings.name = "Non-Color"
		pixels = np.empty(width * height * 4, np.float32)
		back.pixels.foreach_get(pixels)
		bpy.data.images.remove(back)
		return pixels.reshape(height, width, 4)[..., :3]
	finally:
		shutil.rmtree(directory, ignore_errors=True)


def apply_lut(lut: np.ndarray, linear: np.ndarray) -> np.ndarray:
	"""Trilinear lookup, the same as game/shaders/agx_punchy.gdshaderinc."""
	n = lut.shape[0]
	x = np.clip((np.log2(np.maximum(linear, 1e-12)) - LUT_LO) / (LUT_HI - LUT_LO), 0.0, 1.0) * (n - 1)
	i = np.minimum(np.floor(x).astype(int), n - 2)
	f = x - i
	out = np.zeros_like(linear)
	for db in (0, 1):
		for dg in (0, 1):
			for dr in (0, 1):
				weight = ((f[..., 2] if db else 1 - f[..., 2]) * (f[..., 1] if dg else 1 - f[..., 1])
					* (f[..., 0] if dr else 1 - f[..., 0]))
				out += weight[..., None] * lut[i[..., 2] + db, i[..., 1] + dg, i[..., 0] + dr]
	return out


def write_manifest(path: str, frame_size: tuple, view_size: tuple, mug_rect: tuple, ndos_visible: tuple,
		scene: bpy.types.Scene, preview: bool) -> None:
	source = os.path.basename(bpy.data.filepath) or "unsaved"
	stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
	lines = [
		'[gd_resource type="Resource" script_class="FrontManifest" format=3]',
		"",
		'[ext_resource type="Script" path="res://game/front/front_manifest.gd" id="1"]',
		"",
		"[resource]",
		'script = ExtResource("1")',
		"frame_size = Vector2i(%d, %d)" % frame_size,
		"view_size = Vector2i(%d, %d)" % view_size,
		"mug_rect = Rect2i(%d, %d, %d, %d)" % mug_rect,
		"exposure = %r" % float(scene.view_settings.exposure),
		"ndos_visible = Rect2(%r, %r, %r, %r)" % ndos_visible,
		"preview = %s" % ("true" if preview else "false"),
		"samples = %d" % scene.cycles.samples,
		'source = "%s, Blender %s, %s"' % (source, bpy.app.version_string, stamp),
		"",
	]
	with open(path, "w", encoding="utf-8") as file:
		file.write("\n".join(lines))


main()
