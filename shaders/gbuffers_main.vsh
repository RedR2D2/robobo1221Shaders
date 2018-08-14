#extension GL_EXT_gpu_shader4 : enable

varying vec2 texcoord;
varying vec4 color;

varying mat3 tbn;
varying vec3 tangentVec;

varying vec2 lightmaps;

uniform sampler2D tex;

uniform mat4 gbufferModelView;
attribute vec4 at_tangent;

#include "/lib/utilities.glsl"

void main() {
	vec3 viewSpacePosition = transMAD(gl_ModelViewMatrix, gl_Vertex.xyz);
	gl_Position = viewSpacePosition.xyzz * diagonal4(gl_ProjectionMatrix) + gl_ProjectionMatrix[3];

	texcoord = gl_MultiTexCoord0.xy;
	lightmaps = gl_MultiTexCoord1.xy * (1.0 / 255.0);
	color = gl_Color;

	vec3 tangent = at_tangent.xyz / at_tangent.w;
	vec3 normal = gl_Normal;

	#if !defined program_gbuffers_terrain
		normal = (gl_NormalMatrix * normal) * mat3(gbufferModelView);
	#endif

	vec2 atlasSize = vec2(textureSize2D(tex, 0));

	tbn = mat3(tangent, cross(tangent, normal), normal);
	mat3 tangentSize = mat3(tangent * atlasSize.y / atlasSize.x, tbn[1], tbn[2]);

	tangentVec = -normalize((viewSpacePosition * gl_NormalMatrix) * tangentSize);
}
