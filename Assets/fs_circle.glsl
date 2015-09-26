varying mediump vec2 pos;
uniform mediump float phase;
uniform sampler2D s_texture0;
void main() {
  float r = ((pos.x*pos.x)+(pos.y*pos.y));
  float rad = 0.4*0.4;
  float th = 0.002;
  float k = clamp((rad+th-r)/th, 0, 1);
  gl_FragColor = int (r < rad) + k;
}
