shader_type canvas_item;

uniform vec2 motion = vec2(0.0);
uniform float gamma : hint_range(0.0, 2.0, 0.05) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_enable, filter_nearest;
//uniform float alpha : hint_range(1.0, 100.0, 0.5) = 2.0;
//uniform float dither_mod : hint_range(0, 1.0, 0.05) = 0.25;
uniform float dither_size : hint_range(-8.00, 7.99, 0.01) = 1.0;
uniform float bit_depth : hint_range(1.0, 32.0, 0.25);

// FUN

//float fun_get_pixel_brightness(vec3 col) {
	//return (col.r + col.g + col.b) / 3.0;
//}

vec3 gamma_correct (vec3 val) {
	vec3 color;
    color.rgb = pow(val.rgb, vec3(1.0 / gamma));
    return color;
}


float dither_pattern(vec2 pos) {
	int x = int(mod(pos.x, 2.0));
	int y = int(mod(pos.y, 2.0));

	const int bayer2[4] = int[4](
		0, 2,
		3, 1
	);

	int index = x + y * 2;
	return float(bayer2[index]) / 3.0;
}

void fragment(){
	vec4 init_tex = texture(screen_texture, SCREEN_UV);
	vec3 final_color;

	vec2 screen_pos = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float dither = dither_pattern(screen_pos);
	// Posterize in one operation per channel
	vec3 scaled = init_tex.rgb * bit_depth;
	vec3 posterized = clamp(floor(scaled + (dither) * (dither_size / bit_depth)), 0.0, bit_depth) / bit_depth;

	COLOR.rgb = gamma_correct(posterized);
	COLOR.a = init_tex.a;
}
