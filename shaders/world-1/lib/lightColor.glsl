vec3 getAmbienLight(){
	
	vec3 ambientColor = vec3(1.0, 0.01, 0.0001);

	return clamp(ambientColor, 0.0, 1.0);
}

vec3 ambientlight = getAmbienLight();
