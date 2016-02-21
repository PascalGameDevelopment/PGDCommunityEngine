#version 130
varying mediump vec2 pos;                // x-cx, y-cy
uniform mediump vec4 data;               // cx, cy, rad, th
uniform mediump vec4 color;
void main() {
  mediump float r = (pos.x*pos.x)+(pos.y*pos.y);
  mediump float alpha = clamp((data.w*data.w - r) * data.z, 0.0, 1.0);
  gl_FragColor.rgb = color.rgb;
  gl_FragColor.a = color.a * alpha;
}
