#version 120
#define program_composite0
#define VERTEX

varying vec2 texcoord;
varying mat4 shadowMatrix;

flat varying vec2 jitter;

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
varying vec3 sunColorClouds2D;
varying vec3 baseMoonColor;
varying vec3 moonColor;
varying vec3 moonColorClouds;
varying vec3 moonColorClouds2D;
varying vec3 skyColor;

varying float transitionFading;
varying float timeSunrise;

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

void main() {
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0.xy;

	jitter = calculateTemporalJitter() * 0.5;

	const float tTime = (1.0 / 50.0);
	float wTime = float(worldTime);
	transitionFading = clamp01(clamp01((wTime - 23215.0) * tTime) + (1.0 - clamp01((wTime - 12735.0) * tTime)) + clamp01((wTime - 12925.0) * tTime) * (1.0 - clamp01((wTime - 22975.0) * tTime)));
	
	const float endSunriseTime = 1.0 / 3000.0;
	timeSunrise = clamp01(1.0 - clamp01(wTime * endSunriseTime) + clamp01((wTime - 23000.0) * endSunriseTime));

	upVector = upPosition * 0.01;
	sunVector = sunPosition * 0.01;
	moonVector = -sunVector;

	wSunVector = mat3(gbufferModelViewInverse) * sunVector;
	wMoonVector = mat3(gbufferModelViewInverse) * moonVector;

	lightVector = (worldTime > 22975 || worldTime < 12925 ? sunVector : moonVector);
	wLightVector = mat3(gbufferModelViewInverse) * lightVector;

	baseSunColor = sunColorBase;
	baseMoonColor = moonColorBase;

	sunColor = sky_transmittance(vec3(0.0, sky_planetRadius, 0.0), wSunVector, 8) * baseSunColor;
	moonColor = sky_transmittance(vec3(0.0, sky_planetRadius, 0.0), wMoonVector, 8) * baseMoonColor;
	sunColorClouds = sky_transmittance(vec3(0.0, sky_planetRadius + volumetric_cloudMaxHeight, 0.0), wSunVector, 8) * baseSunColor;
	moonColorClouds = sky_transmittance(vec3(0.0, sky_planetRadius + volumetric_cloudMaxHeight, 0.0), wMoonVector, 8) * baseMoonColor;
	sunColorClouds2D = sky_transmittance(vec3(0.0, sky_planetRadius + clouds2D_cloudHeight, 0.0), wSunVector, 6) * baseSunColor;
	moonColorClouds2D = sky_transmittance(vec3(0.0, sky_planetRadius + clouds2D_cloudHeight, 0.0), wMoonVector, 6) * baseMoonColor;

	vec2 planetSphere = vec2(0.0);
	vec3 transmittance = vec3(0.0);

	skyColor = vec3(0.0);
	skyColor = calculateAtmosphere(vec3(0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), wSunVector, wMoonVector, planetSphere, transmittance, 10);

	shadowMatrix = shadowProjection * shadowModelView;
}
