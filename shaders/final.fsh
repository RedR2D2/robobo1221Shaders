#version 120
#define program_final
#define FRAGMENT

varying vec2 texcoord;

uniform sampler2D colortex4;

#include "/lib/utilities.glsl"

vec3 vibranceSaturation(vec3 color){
	const float amountVibrance = VIBRANCE;
	const float amountSaturation = SATURATION;

	float lum = dot(color, lumCoeff);
	float mn = min3(color);
	float mx = max3(color);
	float sat = (1.0 - (mx - mn)) * (1.0 - mx) * lum * 5.0;
	vec3 lig = vec3((mn + mx) * 0.5);

	// Vibrance
	color = mix(color, mix(color, lig, -amountVibrance), sat);

	// Inverse Vibrance
	color = mix(color, lig, (1.0 - lig) * (1.0 - amountVibrance) * 0.5 * abs(amountVibrance));

	// saturation
	color = mix(color, vec3(lum), -amountSaturation);

	return color;
}

vec3 calculateHighDesaturate(vec3 color){
	color.b *= 0.6 + dot(color.rg, vec2(0.1));
	
	return color;
}

vec3 calculareCrossProcess(vec3 color){
	vec3 db = -color + vec3(1.8, 1.5, 1.7);
	vec3 p = mix(db, vec3(0.2, 0.3, 0.4), 0.5);

	color = pow(color * vec3(0.96, 0.97, 0.98) - vec3(0.01, 0.01, -0.02), p);

	return color;
}

void main() {
	vec4 colorSample = texture2D(colortex4, texcoord);
	vec3 color = colorSample.rgb;

	color = vibranceSaturation(color);
	//color = calculateHighDesaturate(color);
	//color = calculareCrossProcess(color);

	gl_FragColor = vec4(color, 1.0);
}
