package none.george.munny.webui.utilities;

import android.content.Context;
import android.content.res.AssetManager;
import android.support.annotation.Nullable;
import android.util.Log;

import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Iterator;

import fi.iki.elonen.NanoHTTPD;
import none.george.munny.Listener;

public class AppServer extends NanoHTTPD {
    private int port;
    private AssetManager assetManager;
    private HashMap<String, String> mimeTypes;
    private File cacheDir;

    public AppServer(Context context) throws Exception {
        super(0);
        start(NanoHTTPD.SOCKET_READ_TIMEOUT, false);
        this.port = getListeningPort();

        this.assetManager = context.getAssets();
        this.cacheDir = context.getCacheDir();
    }

    public int getPort() {
        return this.port;
    }

    @Override
    public Response serve(IHTTPSession session) {
        try {
            String path = "app" + session.getUri();
            String mimeType = getMimeType(path);

            File file = AssetFile.fromPath(path, assetManager, cacheDir);

            return newFixedLengthResponse(Response.Status.OK, mimeType, new FileInputStream(file), file.length());
        } catch (Exception e) {
            Log.e("app server", "Error while serving file", e);
            if(e instanceof FileNotFoundException) {
                return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", e.toString());
            }
            return newFixedLengthResponse(Response.Status.INTERNAL_ERROR, "text/plain", e.toString());
        }
    }

    private String getMimeType(String path) {
        if(mimeTypes == null) {
            initializeMimeTypes();
        }

        String fileName = getFileName(path);
        String extension = getExtension(fileName);

        if(extension == null) {
            return "application/octet-stream";
        }

        String mimeType = mimeTypes.get(extension);
        return mimeType != null ? mimeType : "application/octet-stream";
    }

    private void initializeMimeTypes() {
        InputStream inputStream = null;
        mimeTypes = new HashMap<>();
        try {
            inputStream = assetManager.open("mimeTypes.json");
            StringBuilder jsonString = new StringBuilder();
            byte[] bytes = new byte[8192];
            int read;

            while((read = inputStream.read(bytes, 0, 8192)) > -1) {
                jsonString.append(new String(bytes, 0, read));
            }

            inputStream.close();

            JSONObject json = new JSONObject(jsonString.toString());
            Iterator<String> keys = json.keys();
            while(keys.hasNext()) {
                String key = keys.next();
                mimeTypes.put(key, json.getString(key));
            }
        } catch (Exception e) {
            Log.e("AppServer", "Exception while constructing mimeTypes map", e);
            if(inputStream != null) {
                try { inputStream.close(); } catch (Exception e1) {/*ignored*/}
            }
        }
    }

    @Nullable
    private static String getExtension(String fileName) {
        int extensionIndex = fileName.lastIndexOf('.');
        if(extensionIndex < 0) {
            return null;
        } else {
            return fileName.substring(extensionIndex);
        }
    }

    private static String getFileName(String path) {
        return path.substring(path.lastIndexOf('/') + 1);
    }

    public static void waitForDevServer(String url, Listener<Void> listener) {
        new Thread(() -> {
            try {
                boolean reached = false;

                while(!reached) {
                    Thread.sleep(50);
                    HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
                    try {
                        connection.getInputStream();
                        reached = true;
                    } catch (IOException e) {
                        reached = false;
                    }
                    connection.disconnect();
                }

                Log.d("AppServer", "Dev server reached. Continuing...");
                listener.on(null);
            } catch (Exception e) {
                listener.error(e);
            }

        }).start();
    }
}
