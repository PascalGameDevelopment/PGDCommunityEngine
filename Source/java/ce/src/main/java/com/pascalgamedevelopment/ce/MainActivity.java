/******************************************************************************

    Pascal Game Development Community Engine (PGDCE)

    The contents of this file are subject to the license defined in the file
    'licence.md' which accompanies this file; you may not use this file except
    in compliance with the license.

    This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
    either express or implied.  See the license for the specific language governing
    rights and limitations under the license.

    The Original Code is MainActivity.java

    The Initial Developer of the Original Code is documented in the accompanying
    help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
    2015 of these individuals.

    ******************************************************************************)

{
@abstract(PGDCE Android main activity)

PGDCE Android main activity

@author(George Bakhtadze (avagames@gmail.com))
}
*/
package com.pascalgamedevelopment.ce;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.content.pm.ConfigurationInfo;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.WindowManager;
import android.widget.Toast;

public class MainActivity extends Activity {

    private GLSurfaceView glSurfaceView;
    private boolean rendererSet;
    // Global reference to prevent garbage collection as it's used in native code
    private AssetManager assetManager;

    private boolean isProbablyEmulator() {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH_MR1
                && (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86"));
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ActivityManager activityManager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        ConfigurationInfo configurationInfo = activityManager.getDeviceConfigurationInfo();

        final boolean supportsEs2 =
                configurationInfo.reqGlEsVersion >= 0x20000 || isProbablyEmulator();

        if (supportsEs2) {
            glSurfaceView = new GLSurfaceView(this);

            if (isProbablyEmulator()) {
                // Avoids crashes on startup with some emulator images.
                glSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 0);
            }

            glSurfaceView.setEGLContextClientVersion(2);
            glSurfaceView.setRenderer(new RendererWrapper());
            glSurfaceView.setDebugFlags(GLSurfaceView.DEBUG_CHECK_GL_ERROR | GLSurfaceView.DEBUG_LOG_GL_CALLS);
            rendererSet = true;
            setContentView(glSurfaceView);
        } else {
            // Should never be seen in production, since the manifest filters
            // unsupported devices.
            Toast.makeText(this, "This device does not support OpenGL ES 2.0.",
                    Toast.LENGTH_LONG).show();
            return;
        }

        assetManager = getAssets();
        PGDCELib.init(assetManager);
    }

    @Override
    protected void onPause() {
        super.onPause();
        PGDCELib.onPause();
        if (rendererSet) {
            glSurfaceView.onPause();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (rendererSet) {
            glSurfaceView.onResume();
        }
        PGDCELib.onResume();
    }

    @Override
    public void onLowMemory() {
        super.onLowMemory();
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        System.out.println(String.format("*** KeyPress: (%d, %d) of %d, long: %b, '%s', UC: %d",
                event.getKeyCode(), event.getScanCode(), event.getDeviceId(), event.isLongPress(), event.getDisplayLabel(), event.getUnicodeChar()));
        return PGDCELib.onKeyEvent(event.getAction(), event.getKeyCode(), event.getScanCode());
    }

    @Override
    public boolean onKeyLongPress(int keyCode, KeyEvent event) {
        return super.onKeyLongPress(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        return super.onKeyUp(keyCode, event);
    }

    @Override
    public boolean onKeyMultiple(int keyCode, int repeatCount, KeyEvent event) {
        return super.onKeyMultiple(keyCode, repeatCount, event);
    }

    @Override
    public void onBackPressed() {
        System.out.println("*** back pressed");
        super.onBackPressed();
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int ind = event.getActionIndex();
        int[] coords = new int[2];
        glSurfaceView.getLocationOnScreen(coords);
        float x = event.getX(ind) - coords[0];
        float y = event.getY(ind) - coords[1];

        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN: {
                PGDCELib.onTouchEvent(MotionEvent.ACTION_DOWN, event.getPointerId(ind), x, y);
                return PGDCELib.onTouchEvent(MotionEvent.ACTION_POINTER_DOWN, event.getPointerId(ind), x, y);
            }
            case MotionEvent.ACTION_UP:
                PGDCELib.onTouchEvent(MotionEvent.ACTION_POINTER_UP, event.getPointerId(ind), x, y);
            case MotionEvent.ACTION_CANCEL: {
                PGDCELib.onTouchEvent(MotionEvent.ACTION_CANCEL, event.getPointerId(ind), x, y);
                return true;
            }
            case MotionEvent.ACTION_MOVE: {
                for (int i = 0; i < event.getPointerCount(); i++) {
                    PGDCELib.onTouchEvent(event.getActionMasked(), event.getPointerId(i), event.getX(i) - coords[0], event.getY(i) - coords[1]);
                }
                return true;
            }
            case MotionEvent.ACTION_POINTER_DOWN:
            case MotionEvent.ACTION_POINTER_UP: {
                return PGDCELib.onTouchEvent(event.getActionMasked(), event.getPointerId(ind), x, y);
            }
        }
        return false;
    }

    @Override
    public boolean onGenericMotionEvent(MotionEvent event) {
        return super.onGenericMotionEvent(event);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
    }

    @Override
    public void onWindowAttributesChanged(WindowManager.LayoutParams params) {
        super.onWindowAttributesChanged(params);
    }
}
