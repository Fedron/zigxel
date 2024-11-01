#version 460 core

in vec3 position;
in vec3 color;

out vec4 vertexColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(position.xyz, 1.0);
    vertexColor = vec4(color.xyz, 1.0);
}
