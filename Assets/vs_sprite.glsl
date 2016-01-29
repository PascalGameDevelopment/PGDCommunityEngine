#version 130
attribute vec4 xyuv;
varying mediump vec2 uv;
void main() {
  gl_Position = vec4(xyuv.xy, 0.0, 1.0);
  uv = xyuv.zw;
}
