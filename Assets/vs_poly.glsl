attribute vec3 position;
varying mediump vec3 pos;
void main() {
  gl_Position = vec4(position.xy, 0.0, 1.0);
  pos = position;
}
