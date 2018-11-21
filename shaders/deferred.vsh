#version 120
#define program_deferred
#define VERTEX

varying vec2 texcoord;
varying mat4 shadowMatrix;

flat varying vec2 jitter;

varying mat3x4 skySH;

varying vec3 sunVector;
varying vec3 wSunVector;
varying vec3 moonVector;
varying vec3 wMoonVector;
varying vec3 upVector;
varying vec3 lightVector;
varying vec3 wLightVector;

varying vec3 baseSunColor;
varying vec3 sunColor;
varying vec3 sunColorClouds;
varying vec3 baseMoonColor;
varying vec3 moonColor;
varying vec3 moonColorClouds;
varying vec3 skyColor;

varying float transitionFading;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform float viewWidth;
uniform float viewHeight;

uniform float eyeAltitude;
uniform int worldTime;
uniform int frameCounter;

#include "/lib/utilities.glsl"
#include "/lib/fragment/sky.glsl"
#include "/lib/uniform/TemporalJitter.glsl"

vec4 ToSH(float value, vec3 dir) {
    const float transferl1 = 0.3849 * PI;
    const float sqrt1OverPI = sqrt(rPI);
    const float sqrt3OverPI = sqrt(rPI * 3.0);

    const vec2 halfnhalf = vec2(0.5, -0.5);
    const vec2 transfer = vec2(PI * sqrt1OverPI, transferl1 * sqrt3OverPI);

    const vec4 foo = halfnhalf.xyxy * transfer.xyyy;

    return foo * vec4(1.0, dir.yzx) * value;
}

void CalculateSkySH(vec3 sunVector, vec3 moonVector, vec3 upVector, vec2 planetSphere, vec3 transmittance) {
	const int latSamples = 32;
	const int lonSamples = 16;
	const float rLatSamples = 1.0 / latSamples;
	const float rLonSamples = 1.0 / lonSamples;
	const float sampleCount = rLatSamples * rLonSamples;

	const float latitudeSize = rLatSamples * PI;
	const float longitudeSize = rLonSamples * TAU;

	vec4 shR = vec4(0.0), shG = vec4(0.0), shB = vec4(0.0);

	for (int i = 0; i < latSamples; ++i) {
		float latitude = float(i) * latitudeSize;

		for (int j = 0; j < lonSamples; ++j) {
			float longitude = float(j) * longitudeSize;

			float c = cos(latitude);
			vec3 kernel = vec3(c * cos(longitude), sin(latitude), c * sin(longitude));

			vec3 skyCol = calculateAtmosphere(vec3(0.0), normalize(kernel), upVector, sunVector, moonVector, planetSphere, transmittance, 10);
		
			shR += ToSH(skyCol.r, kernel);
			shG += ToSH(skyCol.g, kernel);
			shB += ToSH(skyCol.b, kernel);
		}
	}

	skySH = mat3x4(shR, shG, shB) * sampleCount;
}

void main() {
	gl_Position.xy = gl_Vertex.xy * 2.0 - 1.0;
	texcoord = gl_MultiTexCoord0.xy;

	jitter = calculateTemporalJitter() * 0.5;

	const float tTime = (1.0 / 50.0);
	float wTime = float(worldTime);
	transitionFading = clamp01(clamp01((wTime - 23215.0) * tTime) + (1.0 - clamp01((wTime - 12735.0) * tTime)) + clamp01((wTime - 12925.0) * tTime) * (1.0 - clamp01((wTime - 22975.0) * tTime)));

	upVector = upPosition * 0.01;
	sunVector = sunPosition * 0.01;
	moonVector = -sunVector;

	wSunVector = mat3(gbufferModelViewInverse) * sunVector;
	wMoonVector = mat3(gbufferModelViewInverse) * moonVector;

	lightVector = (worldTime > 22975 || worldTime < 12925 ? sunVector : moonVector);
	wLightVector = mat3(gbufferModelViewInverse) * lightVector;

	baseSunColor = sunColorBase;
	baseMoonColor = moonColorBase;

	sunColor = sky_transmittance(vec3(0.0, sky_planetRadius, 0.0), wSunVector, 3) * baseSunColor;
	moonColor = sky_transmittance(vec3(0.0, sky_planetRadius, 0.0), wMoonVector, 3) * baseMoonColor;
	sunColorClouds = sky_transmittance(vec3(0.0, sky_planetRadius + volumetric_cloudMaxHeight, 0.0), wSunVector, 3) * baseSunColor;
	moonColorClouds = sky_transmittance(vec3(0.0, sky_planetRadius + volumetric_cloudMaxHeight, 0.0), wMoonVector, 3) * baseMoonColor;
	
	vec2 planetSphere = vec2(0.0);
	vec3 transmittance = vec3(0.0);
	
	skyColor = vec3(0.0);
	skyColor = calculateAtmosphere(vec3(0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), wSunVector, wMoonVector, planetSphere, transmittance, 10);

	shadowMatrix = shadowProjection * shadowModelView;

	CalculateSkySH(wSunVector, wMoonVector, vec3(0.0, 1.0, 0.0), planetSphere, transmittance);
}
