#version 130
varying mediump vec4 pos;     // (x-x1, y-y1, x-x2, y-y2) / len
varying mediump vec4 dat;     // (x-cx, y-cy, ,1/|p2-p1|) / len
uniform mediump vec2 width;
uniform sampler2D s_texture0;
void main() {
    mediump vec4 pos1 = pos - dat.xyxy;
    mediump float r1 = pos1.x*pos1.x + pos1.y*pos1.y;
    mediump float r2 = pos1.z*pos1.z + pos1.w*pos1.w;

    mediump float distMask = (step(1.0, r1) + step(1.0, r2))*1000000.0;
    r1 = pos.x*pos.x + pos.y*pos.y;
    r2 = pos.z*pos.z + pos.w*pos.w;
    mediump float endDist = min(r1, r2);
    mediump float distSq = (dat.x*dat.x + dat.y*dat.y);

    mediump float dist = inversesqrt(min(endDist, distSq + distMask));
    mediump float alpha = width.y*(dist*dat.w - width.x);
    alpha = max(0.0, min(1.0, alpha));
    gl_FragColor = vec4(1.0, 1.0, 1.0, alpha);
    //gl_FragColor = alpha;
    //gl_FragColor = pos;
}
