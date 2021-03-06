#version 330 core

layout (location = 0) in vec3 vertex_position;
layout (location = 1) in vec3 vertex_normal;
layout (location = 2) in vec2 texture_coord;

uniform mat4 model, view, proj;

out vec3 normal;
out vec2 st;


void main()
{
    normal = vertex_normal;
    st = texture_coord;
    
    gl_Position = proj * view * model * vec4(vertex_position, 1.0);
    
}




