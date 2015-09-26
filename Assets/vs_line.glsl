attribute vec4 position;    // (x, y, x2, y2)
attribute vec4 data;        // (cx, cy, x1, y1)
attribute vec2 width;       // (width, threshold)
varying mediump vec4 pos;
varying mediump vec2 dat;
varying mediump vec3 w;
void main() {
  gl_Position = vec4(position.xy, 0.0, 1.0);
  pos = position - data.zwzw;
  vec2 line = pos.zw;
  pos.zw = pos.xy-pos.zw;

  float inv = width.x+width.y;
  w = vec3(inv, width.x*inv/width.y, line.x*line.x+line.y*line.y);
  dat = position.xy - data.xy;
}


//1.0/(1.0/width.x-inv)
//1.0/(width.x+width.y) = 1/wx(1+wy/wx)         -wy/wx^2