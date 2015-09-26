varying mediump vec4 pos;     // (x, y, x-p2.x, y-p2.y)
varying mediump vec2 dat;
varying mediump vec3 w;
uniform mediump float phase;
uniform sampler2D s_texture0;
void main() {
    float r1 = pos.x*pos.x + pos.y*pos.y;
    float r2 = pos.z*pos.z + pos.w*pos.w;

    float endDist = min(r1, r2);
    float distMask = int((r1 > w.z) || (r2 > w.z))*1000000.0;
    float distSq = (dat.x*dat.x + dat.y*dat.y);
    float dist = inversesqrt(min(endDist, distSq + distMask));
    float alpha = (dist - 1/w.x)*w.y;
    gl_FragColor = alpha;
}

