#version 460 core

in vec3 position;
in vec3 color;

out vec4 vertexColor;

void main()
{
    gl_Position = vec4(position.xyz, 1.0);
    vertexColor = vec4(color.xyz, 1.0);
}
