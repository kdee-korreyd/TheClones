shader_type canvas_item;

uniform float time_factor = 1.0; //this will explort the time_factor variable
uniform vec2 amplitude = vec2(1.0,1.0);
uniform float speed = 40.0;

//Vertex Processor -> http://docs.godotengine.org/en/3.0/tutorials/shading/shading_language.html#vertex-processor
//runs once per vertex
void vertex() {
	//TIME is time since godot started
	// update position by modifying VERTEX; VERTEX is the current vertex being processed
	//VERTEX += cos(TIME * time_factor) * amplitude; //VERTEX has xyz (or rgb, rgb accesses the same thing)
}

//Fragment Processor -> http://docs.godotengine.org/en/3.0/tutorials/shading/shading_language.html#fragment-processor
void fragment() {
	//NOTE: UV: The letters "U" and "V" denote the axes of the 2D texture because "X", "Y" and "Z" are already used to denote the axes of the 3D object in model space
	//	so UV is just the coordinates of the texture in relation to the polygon
    vec4 curr_color = texture(TEXTURE,UV); // Get current color of pixel @ coords UV

 	//turn everything red!
	//COLOR = vec4(1,0,0,1);
	
	//if curr_color is red (mario's read, then turn it green)
	//doesnt seem to work as expected
	//if (curr_color == vec4(0.72,0.26,0.2,1)){
	//if (curr_color.r <= 0.72 && curr_color.g <= 0.26 && curr_color.b <= 0.2){
	/*if (curr_color.r <= 0.72){
        COLOR = vec4(0,1,0,1);
    }else{
		COLOR = curr_color;
	}*/

	//change specific colors - going for marios clothing - Pretty Much Works
	//I THINK THAT setting COLOR swaps the current color being used (and it is remembered for the next iteration
	//	hence why you need the else.  if you dont "reset" the color then it will continue to use the COLOR previously set
	/*COLOR = curr_color; //initialize color for this pixel to the original color of the texture
	if ( curr_color.r >= 0.5 && curr_color.r <= 0.8 ) {
		if ( curr_color.g <= 0.45 && curr_color.b <= 0.5 )
			COLOR.r *= 1.1;
	}*/
	//COLOR = curr_color;
	
	//hacky mario star flashing effect
	//changing color based on face (keep face color, swap other colors
	COLOR = curr_color; //initialize color for this pixel to the original color of the texture
	//suspenders
	if ( curr_color.r >= 0.45 && curr_color.g >= 0.38 ) {
		COLOR.r = COLOR.r;
	}
	else {
		if ( curr_color.g <= 0.38 ) {
			COLOR.r = cos(TIME * speed) * COLOR.r;
			//COLOR.g = sin(TIME * speed) * COLOR.g;
		}
	}
	//sleves and hair
	if ( curr_color.r >= 0.45 && curr_color.g >= 0.1 ) {
		COLOR.r = COLOR.r;
	}
	else {
		COLOR.r = cos(TIME * speed) * COLOR.r;
		//COLOR.g = sin(TIME * speed) * COLOR.g;
		//COLOR.b = cos(TIME * speed) * COLOR.b;
	}
}
