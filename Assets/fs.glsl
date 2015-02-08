varying mediump vec2 pos;
uniform mediump float phase;
uniform sampler2D s_texture0;
void main() {
  gl_FragColor = texture2D(s_texture0, pos.xy*sin(sqrt((pos.x*pos.x)+(pos.y*pos.y))*32.0+phase));
}
