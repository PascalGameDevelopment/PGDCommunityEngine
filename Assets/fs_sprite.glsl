#version 130
varying mediump vec2 uv;
uniform lowp vec4 color;
uniform sampler2D s_texture0;
void main() {
  gl_FragColor = texture2D(s_texture0, uv);
}
