#version 130
attribute vec4 position;    // (x, y, x2, y2)
attribute vec4 data;        // (cx, cy, x1, y1)
varying mediump vec4 pos;   // (x-x1, y-y1, x-x2, y-y2) / len
varying mediump vec3 dat;   // (x-cx, y-cy, 1/|p2-p1|)
void main() {
  gl_Position = vec4(position.xy, 0.0, 1.0);
  vec2 dist = position.zw - data.zw;
  float invdist = inversesqrt(dist.x*dist.x+dist.y*dist.y);
  pos = (position - data.zwzw)*invdist;
  pos.zw = pos.xy-pos.zw;

  dat.xy = (position.xy - data.xy)*invdist;
  dat.z = invdist;
}
