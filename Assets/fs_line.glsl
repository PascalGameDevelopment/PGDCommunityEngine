varying mediump vec4 pos;     // (x-x1, y-y1, x-x2, y-y2) / len
varying mediump vec3 dat;     // (x-cx, y-cy, 1/|p2-p1|) / len
uniform mediump vec2 width;
uniform sampler2D s_texture0;
void main() {
    float r1 = pos.x*pos.x + pos.y*pos.y;
    float r2 = pos.z*pos.z + pos.w*pos.w;

    float endDist = min(r1, r2);
    float distMask = (step(1.0, r1) + step(1.0, r2))*1000000.0;
    float distSq = (dat.x*dat.x + dat.y*dat.y);
    float dist = inversesqrt(min(endDist, distSq + distMask));
    float alpha = width.y*(dist*dat.z - width.x);
    //gl_FragColor = vec4(1.0, 1.0, 1.0, alpha);
    gl_FragColor = alpha;
}
