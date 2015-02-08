attribute vec4 position;
varying mediump vec2 pos;
void main() {
  gl_Position = position;
  pos = position.xy;
}
