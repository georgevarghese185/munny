package none.george.munny.webui.utilities;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.os.Handler;
import android.os.Looper;
import android.provider.Telephony.Sms.Inbox;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.List;

import none.george.munny.Listener;


public class SmsReader {

    public static class Sms {
        public final String from;
        public final long date;
        public final String body;

        public Sms(String from, long date, String body) {
            this.from = from;
            this.date = date;
            this.body = body;
        }
    }

    public static void getSms(Context context, long newerThan, Listener<List<Sms>> listener) {
        if(!hasSmsPermission(context)) {
            new Handler(Looper.getMainLooper()).post(() ->
                    listener.error(new IllegalStateException("SMS Permission not granted")));
            return;
        }

        new Thread(() -> {
            ArrayList<Sms> messages = new ArrayList<>();

            Cursor cursor = context.getContentResolver().query(Inbox.CONTENT_URI,
                    new String[]{Inbox.ADDRESS, Inbox.BODY, Inbox.DATE},
                    Inbox.DATE + " >= ?",
                    new String[]{String.valueOf(newerThan)},
                    null);

            if(cursor != null && cursor.moveToFirst()) {

                do {
                    String address = cursor.getString(cursor.getColumnIndex(Inbox.ADDRESS));
                    String body = cursor.getString(cursor.getColumnIndex(Inbox.BODY));
                    long date = cursor.getLong(cursor.getColumnIndex(Inbox.DATE));

                    messages.add(new Sms(address, date, body));
                } while (cursor.moveToNext());

                cursor.close();
            }

            new Handler(Looper.getMainLooper()).post(() -> listener.on(messages));
        }).start();
    }

    public static boolean hasSmsPermission(Context context) {
        return ContextCompat.checkSelfPermission(context, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED;
    }
}
