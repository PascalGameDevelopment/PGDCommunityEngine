#version 130
attribute vec3 position;                 // x, y
uniform mediump vec4 data;               // cx, cy, rad, th
varying mediump vec2 pos;                // x-cx, y-cy
void main() {
  gl_Position = vec4(position.xy, 0.0, 1.0);
  pos = position.xy - data.xy;
}
