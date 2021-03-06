/*
 * Copyright 2017 Cheng Cao
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// =============================================================================
//  PLEASE FOLLOW THE LICENSE AND PLEASE DO NOT REMOVE THE LICENSE HEADER
// =============================================================================
//  ANY USE OF THE SHADER ONLINE OR OFFLINE IS CONSIDERED AS INCLUDING THE CODE
//  IF YOU DOWNLOAD THE SHADER, IT MEANS YOU AGREE AND OBSERVE THIS LICENSE
// =============================================================================

#version 130

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_texture_lod : require

#pragma optimize(on)

#define SMOOTH_TEXTURE

#define NORMALS

uniform sampler2D texture;
uniform sampler2D specular;
#ifdef NORMALS
uniform sampler2D normals;
#endif

layout(location = 0) in lowp vec4 color;
layout(location = 1) in lowp vec3 normal;
layout(location = 2) in highp vec2 texcoord;
layout(location = 3) in highp vec3 wpos;
layout(location = 4) in lowp vec2 lmcoord;
layout(location = 5) in float flag;

#ifdef NORMALS
layout(location = 6) in vec3 tangent;
layout(location = 7) in vec3 binormal;
#endif

#ifdef SMOOTH_TEXTURE
#define texF texSmooth
uniform ivec2 atlasSize;

vec4 texSmooth(in sampler2D s, in vec2 texc) {
	float lod = length(dFdx(wpos) + dFdy(wpos)) * 8.0;

	vec2 pix_size = vec2(1.0) / (vec2(atlasSize) * 24.0);

	vec4 texel0 = texture2DLod(s, texc + pix_size * vec2(0.1, 0.5), lod);
	vec4 texel1 = texture2DLod(s, texc + pix_size * vec2(0.5, -0.1), lod);
	vec4 texel2 = texture2DLod(s, texc + pix_size * vec2(-0.1, -0.5), lod);
	vec4 texel3 = texture2DLod(s, texc + pix_size * vec2(0.5, 0.1), lod);

	return (texel0 + texel1 + texel2 + texel3) * 0.25;
}
#else
#define texF texture2D
#endif

//#define ParallaxOcculusion
/*#ifdef ParallaxOcculusion
in vec2 midTexCoord;
in vec3 TangentFragPos;
in vec4 vtexcoordam;

const float height_scale = 0.018;

vec2 ParallaxMapping(vec2 texc, vec3 viewDir) {
	float height = texture2D(normals, texc).a;
	vec2 p = viewDir.xy / viewDir.z * (height * height_scale);
	return texc - p;
}
#endif*/

vec2 normalEncode(vec3 n) {
	vec2 enc = normalize(n.xy) * (sqrt(-n.z*0.5+0.5));
	enc = enc*0.5+0.5;
	return enc;
}

/* DRAWBUFFERS:01245 */
void main() {
	vec2 texcoord_adj = texcoord;
	/*#ifdef ParallaxOcculusion
	texcoord_adj = ParallaxMapping(texcoord, TangentFragPos);
	texcoord_adj = fract(texcoord_adj / vtexcoordam.pq) * vtexcoordam.pq + vtexcoordam.st;
	#endif*/

	gl_FragData[0] = texF(texture, texcoord_adj) * color;
	gl_FragData[1] = vec4(wpos, 1.0);
	#ifdef NORMALS
		if (length(wpos) < 96.0) {
			vec3 normal2 = texF(normals, texcoord_adj).xyz * 2.0 - 1.0;
			const float bumpmult = 0.35;
			normal2 = normal2 * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
			mat3 tbnMatrix = mat3(
				tangent.x, binormal.x, normal.x,
				tangent.y, binormal.y, normal.y,
				tangent.z, binormal.z, normal.z);
			gl_FragData[2] = vec4(normalEncode(normal2 * tbnMatrix), flag, 1.0);
		} else {
			gl_FragData[2] = vec4(normalEncode(normal), flag, 1.0);
		}
	#else
		gl_FragData[2] = vec4(normalEncode(normal), flag, 1.0);
	#endif
	gl_FragData[3] = texture2D(specular, texcoord_adj);
	gl_FragData[4] = vec4(lmcoord, 1.0, 1.0);
}
