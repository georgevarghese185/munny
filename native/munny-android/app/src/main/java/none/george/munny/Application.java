package none.george.munny;

import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.util.Log;

import none.george.munny.webui.utilities.AssetFile;

public class Application extends android.app.Application {
    private String LAST_INSTALLED_VERSION = "last_installed_version";

    @Override
    public void onCreate() {
        super.onCreate();

        try {
            if(versionChanged() || BuildConfig.DEBUG) {
                AssetFile.clearCachedAssets(getCacheDir());
            }
        } catch (Exception e) {
            Log.e("Application", "Error while checking version", e);
        }

    }

    private boolean versionChanged() throws Exception {
        SharedPreferences preferences = getSharedPreferences(getPackageName(), MODE_PRIVATE);
        PackageInfo packageInfo = getPackageManager().getPackageInfo(getPackageName(), 0);

        if(!preferences.contains(LAST_INSTALLED_VERSION)) {
            SharedPreferences.Editor editor = preferences.edit();

            editor.putInt(LAST_INSTALLED_VERSION, packageInfo.versionCode);
            editor.apply();
        }

        int lastInstalledVersion = preferences.getInt(LAST_INSTALLED_VERSION, 0);
        int currentVersion = packageInfo.versionCode;

        return currentVersion != lastInstalledVersion;
    }
}
