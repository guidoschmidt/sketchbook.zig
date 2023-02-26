#version 330 core

in vec3 v_position;

out vec4 FragColor;
        
void main()
{
  vec3 pos = v_position / 1.0;
  FragColor = vec4(pos, 1.0f);
}

