class_name StepGradient
## A gradient of equal hard steps, rasterised the way Figma does it: a row of pixels that a step boundary
## crosses gets the mix of both steps by how much of the row each covers.


## One colour per pixel row, top to bottom, for steps spread evenly over height rows.
static func rows(steps: Array[Color], height: int) -> PackedColorArray:
	var result := PackedColorArray()
	var step_height: float = float(height) / steps.size()
	for y: int in height:
		var color := Color(0, 0, 0, 0)
		for i: int in steps.size():
			var overlap: float = minf(y + 1, (i + 1) * step_height) - maxf(y, i * step_height)
			if overlap > 0.0:
				color += steps[i] * overlap
		result.append(color)
	return result
