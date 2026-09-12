package com.ritrodan.alcloud.gate2probe;

import android.app.Activity;
import android.opengl.GLES30;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public final class MainActivity extends Activity {
    private GLSurfaceView glView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        hideSystemUi();

        glView = new GLSurfaceView(this);
        glView.setEGLContextClientVersion(3);
        glView.setPreserveEGLContextOnPause(true);
        glView.setRenderer(new ProbeRenderer());
        glView.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        setContentView(glView);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            hideSystemUi();
        }
    }

    @Override
    protected void onPause() {
        glView.onPause();
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        glView.onResume();
    }

    private void hideSystemUi() {
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }

    private static final class ProbeRenderer implements GLSurfaceView.Renderer {
        private static final String TAG = "ALCLOUD_GLES_PROBE";

        private static final String VERTEX_SHADER =
                "#version 300 es\n"
                        + "layout(location = 0) in vec2 aPosition;\n"
                        + "layout(location = 1) in vec2 aTexCoord;\n"
                        + "uniform float uAngle;\n"
                        + "uniform float uScale;\n"
                        + "uniform vec2 uOffset;\n"
                        + "out vec2 vTexCoord;\n"
                        + "void main() {\n"
                        + "  float c = cos(uAngle);\n"
                        + "  float s = sin(uAngle);\n"
                        + "  mat2 r = mat2(c, -s, s, c);\n"
                        + "  vec2 p = r * (aPosition * uScale) + uOffset;\n"
                        + "  gl_Position = vec4(p, 0.0, 1.0);\n"
                        + "  vTexCoord = aTexCoord;\n"
                        + "}\n";

        private static final String FRAGMENT_SHADER =
                "#version 300 es\n"
                        + "precision highp float;\n"
                        + "in vec2 vTexCoord;\n"
                        + "uniform sampler2D uTexture;\n"
                        + "uniform float uTime;\n"
                        + "uniform float uAlpha;\n"
                        + "out vec4 fragColor;\n"
                        + "void main() {\n"
                        + "  vec4 texel = texture(uTexture, vTexCoord);\n"
                        + "  vec3 pulse = 0.5 + 0.5 * sin(vec3(1.0, 1.7, 2.3) * uTime + vec3(0.0, 1.2, 2.4));\n"
                        + "  vec3 rgb = mix(texel.rgb, pulse, 0.22);\n"
                        + "  fragColor = vec4(rgb, texel.a * uAlpha);\n"
                        + "}\n";

        private final FloatBuffer vertices;
        private int program;
        private int texture;
        private int uAngle;
        private int uScale;
        private int uOffset;
        private int uTime;
        private int uAlpha;
        private int width;
        private int height;
        private long startNanos;
        private long frames;
        private int surfaceSequence;

        ProbeRenderer() {
            float[] data = {
                    -0.82f, -0.82f, 0.0f, 1.0f,
                     0.82f, -0.82f, 1.0f, 1.0f,
                    -0.82f,  0.82f, 0.0f, 0.0f,
                     0.82f,  0.82f, 1.0f, 0.0f
            };
            ByteBuffer bytes = ByteBuffer.allocateDirect(data.length * Float.BYTES)
                    .order(ByteOrder.nativeOrder());
            vertices = bytes.asFloatBuffer();
            vertices.put(data).position(0);
        }

        @Override
        public void onSurfaceCreated(GL10 unused, EGLConfig config) {
            surfaceSequence++;
            startNanos = System.nanoTime();
            frames = 0;

            String vendor = GLES30.glGetString(GLES30.GL_VENDOR);
            String renderer = GLES30.glGetString(GLES30.GL_RENDERER);
            String version = GLES30.glGetString(GLES30.GL_VERSION);
            String glsl = GLES30.glGetString(GLES30.GL_SHADING_LANGUAGE_VERSION);
            Log.i(TAG, "SURFACE_CREATED seq=" + surfaceSequence
                    + " vendor=" + vendor
                    + " renderer=" + renderer
                    + " version=" + version
                    + " glsl=" + glsl);

            program = linkProgram(
                    compileShader(GLES30.GL_VERTEX_SHADER, VERTEX_SHADER),
                    compileShader(GLES30.GL_FRAGMENT_SHADER, FRAGMENT_SHADER));

            uAngle = GLES30.glGetUniformLocation(program, "uAngle");
            uScale = GLES30.glGetUniformLocation(program, "uScale");
            uOffset = GLES30.glGetUniformLocation(program, "uOffset");
            uTime = GLES30.glGetUniformLocation(program, "uTime");
            uAlpha = GLES30.glGetUniformLocation(program, "uAlpha");

            int[] textures = new int[1];
            GLES30.glGenTextures(1, textures, 0);
            texture = textures[0];
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, texture);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_LINEAR);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_LINEAR);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_REPEAT);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_REPEAT);

            final int texWidth = 64;
            final int texHeight = 64;
            ByteBuffer pixels = ByteBuffer.allocateDirect(texWidth * texHeight * 4)
                    .order(ByteOrder.nativeOrder());
            for (int y = 0; y < texHeight; y++) {
                for (int x = 0; x < texWidth; x++) {
                    boolean checker = (((x / 8) + (y / 8)) & 1) == 0;
                    int r = checker ? 238 : 24;
                    int g = checker ? (x * 255 / (texWidth - 1)) : 72;
                    int b = checker ? 48 : (y * 255 / (texHeight - 1));
                    pixels.put((byte) r);
                    pixels.put((byte) g);
                    pixels.put((byte) b);
                    pixels.put((byte) 255);
                }
            }
            pixels.position(0);
            GLES30.glTexImage2D(
                    GLES30.GL_TEXTURE_2D,
                    0,
                    GLES30.GL_RGBA,
                    texWidth,
                    texHeight,
                    0,
                    GLES30.GL_RGBA,
                    GLES30.GL_UNSIGNED_BYTE,
                    pixels);

            GLES30.glUseProgram(program);
            GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "uTexture"), 0);
            checkGl("onSurfaceCreated");
            Log.i(TAG, "SHADERS_AND_TEXTURE_READY program=" + program + " texture=" + texture);
        }

        @Override
        public void onSurfaceChanged(GL10 unused, int newWidth, int newHeight) {
            width = newWidth;
            height = newHeight;
            GLES30.glViewport(0, 0, width, height);
            Log.i(TAG, "SURFACE_CHANGED seq=" + surfaceSequence + " width=" + width + " height=" + height);
        }

        @Override
        public void onDrawFrame(GL10 unused) {
            float seconds = (System.nanoTime() - startNanos) / 1_000_000_000.0f;
            float clearR = 0.06f + 0.04f * (float) Math.sin(seconds * 0.73f);
            float clearG = 0.08f + 0.04f * (float) Math.sin(seconds * 0.51f + 1.0f);
            float clearB = 0.14f + 0.05f * (float) Math.sin(seconds * 0.37f + 2.0f);
            GLES30.glClearColor(clearR, clearG, clearB, 1.0f);
            GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT);

            GLES30.glUseProgram(program);
            GLES30.glActiveTexture(GLES30.GL_TEXTURE0);
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, texture);

            vertices.position(0);
            GLES30.glEnableVertexAttribArray(0);
            GLES30.glVertexAttribPointer(0, 2, GLES30.GL_FLOAT, false, 4 * Float.BYTES, vertices);
            vertices.position(2);
            GLES30.glEnableVertexAttribArray(1);
            GLES30.glVertexAttribPointer(1, 2, GLES30.GL_FLOAT, false, 4 * Float.BYTES, vertices);

            GLES30.glDisable(GLES30.GL_BLEND);
            GLES30.glUniform1f(uAngle, seconds * 0.31f);
            GLES30.glUniform1f(uScale, 0.93f);
            GLES30.glUniform2f(uOffset, 0.0f, 0.0f);
            GLES30.glUniform1f(uTime, seconds);
            GLES30.glUniform1f(uAlpha, 1.0f);
            GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4);

            GLES30.glEnable(GLES30.GL_BLEND);
            GLES30.glBlendFunc(GLES30.GL_SRC_ALPHA, GLES30.GL_ONE_MINUS_SRC_ALPHA);
            GLES30.glUniform1f(uAngle, -seconds * 0.67f);
            GLES30.glUniform1f(uScale, 0.42f + 0.06f * (float) Math.sin(seconds));
            GLES30.glUniform2f(
                    uOffset,
                    0.30f * (float) Math.sin(seconds * 0.43f),
                    0.22f * (float) Math.cos(seconds * 0.59f));
            GLES30.glUniform1f(uTime, seconds + 1.7f);
            GLES30.glUniform1f(uAlpha, 0.56f);
            GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4);
            GLES30.glDisable(GLES30.GL_BLEND);

            frames++;
            if (frames == 1 || frames % 300 == 0) {
                int error = GLES30.glGetError();
                Log.i(TAG, "FRAME frame=" + frames
                        + " elapsed_s=" + String.format(java.util.Locale.US, "%.3f", seconds)
                        + " surface=" + width + "x" + height
                        + " gl_error=0x" + Integer.toHexString(error));
            }
        }

        private static int compileShader(int type, String source) {
            int shader = GLES30.glCreateShader(type);
            GLES30.glShaderSource(shader, source);
            GLES30.glCompileShader(shader);
            int[] status = new int[1];
            GLES30.glGetShaderiv(shader, GLES30.GL_COMPILE_STATUS, status, 0);
            if (status[0] == 0) {
                String log = GLES30.glGetShaderInfoLog(shader);
                GLES30.glDeleteShader(shader);
                Log.e(TAG, "SHADER_COMPILE_FAILED type=" + type + " log=" + log);
                throw new IllegalStateException("Shader compile failed: " + log);
            }
            return shader;
        }

        private static int linkProgram(int vertexShader, int fragmentShader) {
            int result = GLES30.glCreateProgram();
            GLES30.glAttachShader(result, vertexShader);
            GLES30.glAttachShader(result, fragmentShader);
            GLES30.glLinkProgram(result);
            int[] status = new int[1];
            GLES30.glGetProgramiv(result, GLES30.GL_LINK_STATUS, status, 0);
            GLES30.glDeleteShader(vertexShader);
            GLES30.glDeleteShader(fragmentShader);
            if (status[0] == 0) {
                String log = GLES30.glGetProgramInfoLog(result);
                GLES30.glDeleteProgram(result);
                Log.e(TAG, "PROGRAM_LINK_FAILED log=" + log);
                throw new IllegalStateException("Program link failed: " + log);
            }
            return result;
        }

        private static void checkGl(String phase) {
            int error = GLES30.glGetError();
            if (error != GLES30.GL_NO_ERROR) {
                Log.e(TAG, phase + " gl_error=0x" + Integer.toHexString(error));
                throw new IllegalStateException(phase + " GL error 0x" + Integer.toHexString(error));
            }
        }
    }
}
