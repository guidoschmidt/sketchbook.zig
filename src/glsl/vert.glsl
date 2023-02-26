// VERTEX SHADER
#version 330 core

layout (location = 0) in vec3 aPos;
    
uniform float u_time;
    
out vec3 v_position;
    
mat2 rotate2D(in float a) {
  return mat2(cos(a), -sin(a),
              sin(a), cos(a));
}
     
void main()
{
  v_position = aPos;
  v_position.xy *= rotate2D(u_time);
  v_position.x += sin(u_time * 0.2) * 0.25;
  v_position.y += cos(u_time * 0.3) * 0.25;
  gl_Position = vec4(v_position, 1.0);
}
