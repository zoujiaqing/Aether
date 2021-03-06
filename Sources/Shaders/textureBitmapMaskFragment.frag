
#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 5) uniform sampler2D source;
layout (binding = 6) uniform sampler2D mask;

layout (location = 0) in vec4 inColor;
layout (location = 1) in vec2 inUV;
layout (location = 2) in vec2 inUVmask;

layout (location = 0) out vec4 outFragColor;


void main() {
    vec4 c = texture(source, inUV);
    vec4 m = texture(mask, inUVmask);
    outFragColor =  vec4(c.rgb,m.a*m.r*c.a)*inColor;
}
