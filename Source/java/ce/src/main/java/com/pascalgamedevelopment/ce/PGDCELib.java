/******************************************************************************

    Pascal Game Development Community Engine (PGDCE)

    The contents of this file are subject to the license defined in the file
    'licence.md' which accompanies this file; you may not use this file except
    in compliance with the license.

    This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
    either express or implied.  See the license for the specific language governing
    rights and limitations under the license.

    The Original Code is PGDCELib.java

    The Initial Developer of the Original Code is documented in the accompanying
    help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
    2015 of these individuals.

    ******************************************************************************)

{
@abstract(PGDCE Android jni library wrapper)

PGDCE Android jni library wrapper

@author(George Bakhtadze (avagames@gmail.com))
}
*/
package com.pascalgamedevelopment.ce;

import android.content.res.AssetManager;

public class PGDCELib {

    public static native void init(AssetManager assetManager);
    public static native void onSurfaceCreated();
    public static native void onSurfaceChanged(int width, int height);
    public static native void drawFrame();

    public static native void setConfig(String configString);
    public static native void onPause();
    public static native void onResume();

    public static native boolean onKeyEvent(int action, int keyCode, int scanCode);
    public static native boolean onTouchEvent(int action, int pointerId, float x, float y);

    static {
        System.out.println("Library loading...");
        System.loadLibrary("pgdce");
        System.out.println("Library loaded");
    }

}