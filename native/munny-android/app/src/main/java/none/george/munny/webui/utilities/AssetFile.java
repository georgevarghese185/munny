package none.george.munny.webui.utilities;

import android.content.res.AssetManager;
import android.support.annotation.Nullable;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class AssetFile {
    private static final String CACHED_ASSETS_DIR = "cached_assets";

    public static File fromPath(String assetFilePath, AssetManager assetManager, File cacheDir) throws Exception {
        File file = new File(cacheDir,  "/" + CACHED_ASSETS_DIR + "/" + assetFilePath);
        if(file.exists()) {
            return file;
        } else {
            return cache(assetFilePath, assetManager, cacheDir);
        }
    }

    private static File cache(String assetFilePath, AssetManager assetManager, File cacheDir) throws Exception {
        InputStream inputStream = null;
        FileOutputStream fos = null;

        try {
            inputStream = assetManager.open(assetFilePath);
            File file = new File(cacheDir.getAbsolutePath() + "/" + CACHED_ASSETS_DIR + "/" + assetFilePath);
            byte[] bytes = new byte[8192];
            int read;

            createFile(file, false);
            fos = new FileOutputStream(file);

            while ((read = inputStream.read(bytes, 0, 8192)) > -1) {
                fos.write(bytes, 0, read);
            }

            inputStream.close();
            fos.close();

            return file;
        } catch (Exception e) {
            if(inputStream != null) {
                try { inputStream.close(); } catch (Exception e1) {/*ignored*/}
            }
            if(fos != null) {
                try { fos.close(); } catch (Exception e1) {/*ignored*/}
            }
            throw e;
        }
    }

    private static void createFile(File file, boolean dir) throws Exception {
        if(file.exists()) {
            file.delete();
        }

        if(!file.getParentFile().exists()) {
            createFile(file.getParentFile(), true);
        }

        if(dir) {
            file.mkdir();
        } else {
            file.createNewFile();
        }
    }

    public static void clearCachedAssets(File cacheDir) {
        if(!cacheDir.exists() && !cacheDir.isDirectory()) {
            return;
        }

        File cachedAssets = getCachedAssets(cacheDir);
        if(cachedAssets != null) {
            deleteFile(cachedAssets);
        }
    }

    private static boolean deleteFile(File file) {
        if(file.exists()) {
            if(file.isDirectory()) {
                for(File f : file.listFiles()) {
                    deleteFile(f);
                }
            }

            return file.delete();
        } else {
            return true;
        }
    }

    @Nullable
    private static File getCachedAssets(File cacheDir) {
        for(File file : cacheDir.listFiles()) {
            if(file.getName().equals(CACHED_ASSETS_DIR)) {
                return file;
            }
        }

        return null;
    }
}
