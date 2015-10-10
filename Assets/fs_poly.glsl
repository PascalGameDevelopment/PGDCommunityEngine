varying mediump vec3 pos;
uniform lowp vec4 color;
uniform sampler2D s_texture0;
void main() {
  gl_FragColor.rgb = color.rgb;
  gl_FragColor.a = color.a*pos.z;
}
