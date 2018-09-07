package none.george.munny;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.os.Handler;
import android.os.Looper;
import android.provider.Telephony.Sms.Inbox;
import android.support.v4.content.ContextCompat;

import java.util.ArrayList;
import java.util.List;


public class SmsReader {

    public static void getSms(Context context, long newerThan, Listener<List<String>> listener) {
        if(!hasSmsPermission(context)) {
            new Handler(Looper.getMainLooper()).post(() ->
                    listener.error(new IllegalStateException("SMS Permission not granted")));
            return;
        }

        new Thread(() -> {
            ArrayList<String> messages = new ArrayList<>();

            Cursor cursor = context.getContentResolver().query(Inbox.CONTENT_URI,
                    new String[]{Inbox.ADDRESS, Inbox.BODY},
                    Inbox.DATE + " >= ?",
                    new String[]{String.valueOf(newerThan)},
                    null);

            if(cursor != null && cursor.moveToFirst()) {

                do {
                    String address = cursor.getString(cursor.getColumnIndex(Inbox.ADDRESS));
                    String body = cursor.getString(cursor.getColumnIndex(Inbox.BODY));
                    long date = cursor.getLong(cursor.getColumnIndex(Inbox.DATE));

                    String message = String.format("%s:%s:%s", address, body, String.valueOf(date));
                    messages.add(message);
                } while (cursor.moveToNext());

                cursor.close();
            }

            new Handler(Looper.getMainLooper()).post(() -> listener.on(messages));
        }).start();
    }

    private static boolean hasSmsPermission(Context context) {
        return ContextCompat.checkSelfPermission(context, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED;
    }
}
