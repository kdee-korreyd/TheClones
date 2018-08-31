shader_type canvas_item;

uniform float speed = 40.0;
uniform int go = 0;

//Vertex Processor -> http://docs.godotengine.org/en/3.0/tutorials/shading/shading_language.html#vertex-processor
//runs once per vertex
void vertex() {
}

//Fragment Processor -> http://docs.godotengine.org/en/3.0/tutorials/shading/shading_language.html#fragment-processor
void fragment() {
	vec4 curr_color = texture(TEXTURE,UV); // Get current color of pixel @ coords UV
	COLOR = curr_color; //initialize color for this pixel to the original color of the texture
	if ( go > 0 ){
		//hacky mario star flashing effect
		//changing color based on face (keep face color, swap other colors
		//	suspenders
		if ( curr_color.r >= 0.45 && curr_color.g >= 0.38 ) {
			COLOR.r = COLOR.r;
		}
		else {
			if ( curr_color.g <= 0.38 ) {
				COLOR.r = cos(TIME * speed) * COLOR.r;
				//COLOR.g = sin(TIME * speed) * COLOR.g;
			}
		}
		//	sleves and hair
		if ( curr_color.r >= 0.45 && curr_color.g >= 0.1 ) {
			COLOR.r = COLOR.r;
		}
		else {
			COLOR.r = cos(TIME * speed) * COLOR.r;
			//COLOR.g = sin(TIME * speed) * COLOR.g;
			//COLOR.b = cos(TIME * speed) * COLOR.b;
		}
	}
}