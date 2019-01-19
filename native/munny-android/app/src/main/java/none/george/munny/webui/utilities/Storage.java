package none.george.munny.webui.utilities;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.Nullable;

public class Storage {
    public static final String SHARED_PREFERENCES_NAME = "local_store";

    private static SharedPreferences getPreferences(Context context) {
        return context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE);
    }

    public static void store(Context context, String key, String value) {
        getPreferences(context).edit().putString(key, value).apply();
    }

    @Nullable
    public static String get(Context context, String key) {
        return getPreferences(context).getString(key, null);
    }

    public static void clear(Context context, String key) {
        getPreferences(context).edit().remove(key).apply();
    }
}
