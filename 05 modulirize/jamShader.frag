#version 330 core

in vec3 normal;
in vec2 st;

out vec4 fragColor;

void main()
{
    vec3 ambient = vec3(0.1,0.1,0.1);
    vec3 diffuse_color = vec3(1.0,1.0,1.0);
    vec3 light_direction = vec3(-1.0, 1.0, 1.0);
    float light_intensity = clamp(dot(normal, light_direction), 0.0f, 1.0f);

    vec3 output_color =  clamp( diffuse_color * light_intensity  * 0.8 + ambient, 0.0f, 1.0f);
    output_color = output_color * vec3(1.0,1.0,1.0);

    fragColor = vec4(output_color, 1.0);
}














