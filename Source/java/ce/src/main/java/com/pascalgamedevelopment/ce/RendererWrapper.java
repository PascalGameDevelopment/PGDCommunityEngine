/******************************************************************************

    Pascal Game Development Community Engine (PGDCE)

    The contents of this file are subject to the license defined in the file
    'licence.md' which accompanies this file; you may not use this file except
    in compliance with the license.

    This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
    either express or implied.  See the license for the specific language governing
    rights and limitations under the license.

    The Original Code is RendererWrapper.java

    The Initial Developer of the Original Code is documented in the accompanying
    help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
    2015 of these individuals.

    ******************************************************************************)

{
@abstract(PGDCE Android renderer wrapper)

PGDCE Android renderer wrapper

@author(George Bakhtadze (avagames@gmail.com))
}
*/
package com.pascalgamedevelopment.ce;

import android.opengl.GLSurfaceView;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class RendererWrapper implements GLSurfaceView.Renderer {
    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        PGDCELib.onSurfaceCreated();
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        PGDCELib.onSurfaceChanged(width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        PGDCELib.drawFrame();
    }


}