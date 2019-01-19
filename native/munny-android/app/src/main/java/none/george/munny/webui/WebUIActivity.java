package none.george.munny.webui;

import android.Manifest;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import none.george.munny.BuildConfig;

import none.george.munny.Listener;
import none.george.munny.R;
import none.george.munny.webscripter.Script;
import none.george.munny.webscripter.WebScripter;
import none.george.munny.webui.utilities.AppServer;
import none.george.munny.webui.utilities.SmsReader;
import none.george.munny.webui.utilities.Storage;
import none.george.munny.webui.utilities.secrets.AuthenticationHelper;
import none.george.munny.webui.utilities.secrets.EncryptionHelper;
import none.george.munny.webui.utilities.secrets.EncryptionException;

public class WebUIActivity extends AppCompatActivity {

    private WebView uiView;
    private Map<String, WebScripter> webScripters;
    private int SMS_REQUEST_CODE = 1;
    private String smsCallback;
    private long smsNewerThan;
    private String visibleScripter;
    private AppServer appServer;

    public static final int AUTH_REQUEST_CODE = 2;
    public Listener<Integer> authListener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_web_ui);

        if(BuildConfig.DEBUG) {
            WebView.setWebContentsDebuggingEnabled(true);
        }

        webScripters = new HashMap<>();
        uiView = WebScripter.setupWebView(findViewById(R.id.ui_web_view));
        uiView.setWebViewClient(new WebViewClient());
        uiView.addJavascriptInterface(this, "__Native_Interface");

        if(BuildConfig.DEBUG) {
            waitForDevServer();
        } else {
            startAppServer();
        }
    }


    private void waitForDevServer() {
        final String url = getString(R.string.debug_url) + "/index.html";

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Waiting for Dev server")
                .setMessage("Looking for start page on " + url)
                .setCancelable(false)
                .create();
        dialog.show();

        AppServer.waitForDevServer(url, new Listener<Void>() {
            @Override
            public void on(Void result) {
                runOnUiThread(() -> {
                    dialog.hide();
                    uiView.loadUrl(url);
                });
            }

            @Override
            public void error(Exception e) {
                Log.e("WebUIActivity", "Error while waiting for dev server", e);
            }
        });
    }

    private void startAppServer() {
        try {
            appServer = new AppServer(this);
            String port = String.valueOf(appServer.getPort());
            uiView.loadUrl("http://localhost:" + port + "/index.html");
        } catch (Exception e) {
            Log.e("WebUIActivity", "Error while starting app server", e);
            finish();
        }
    }


    /**
     * Creates a new Web Scripter which is just a Web View with a JavaScript Interface injected
     * and which can be controlled using some other functions defined below using the Scripter's id
     *
     * @param id The id you want to reference the new Web Scripter by
     * @param callback Success callback when the Web Scripter is created
     */
    @JavascriptInterface
    public void spawnWebScripter(String id, String callback) {
        runOnUiThread(() -> {
            if(webScripters.containsKey(id)) {
                killScripter(id);
            }
            webScripters.put(id, new WebScripter(this));
            callback(callback);
        });
    }

    /**
     * Delete and remove a created Web Scripter. Nothing happens if the Scripter does not exist
     *
     * @param id id given to the Scripter when it was created using {@link #spawnWebScripter(String, String)}
     */
    @JavascriptInterface
    public void killScripter(String id) {
        WebScripter webScripter = webScripters.get(id);
        hideScripter(id);
        webScripter.kill();
        webScripters.remove(id);
    }

    /**
     * After a WebScripter has been created, you can execute a scripter on it using this
     * method. The scripter passed to this method must be a stringified JSON Array of the following
     * format:
     *      [
     *         {
     *             type: "URL\JS",
     *             command: "url|js script"
     *         }
     *      ]
     *
     * The array must contain objects with two fields: `type` and `command`.
     * `type` Can be either "URL" or "JS".
     *
     * If `type` is "URL", then whatever is given in the `command` field will be considered as a URL.
     * This willinstruct the WebScripter to load that URL.
     *
     * If `type` is "JS" then the `command` field is expected to be JavaScript
     * code as a string that can be evaluated. This JavaScript code can also
     * make use of the functions available in the {@link Script.Interface}
     * JavaScript Interface class.
     * 
     * Each such object is considered as a "step" for the executor to execute and will be executed
     * in the same order as in the JSON array. If a step is a "URL" step, the given URL will be
     * loaded and the next step will be put on hold till the URL finishes loading (ie. the
     * "onPageFinished" event happens). If the step is a "JS" step, the next step will be put on
     * hold until {@link Script.Interface#onCommandDone(String)} is called from inside the Web
     * Scripter with a supplied String result or null.
     *
     * When the scripter's steps are completed, the result returned will be a stringified JSON
     * array of Strings. If nothing goes wrong, the number of items in the result array will be
     * equal to the number of steps in the scripter. If a step was a URL step, the corresponding
     * item in the result array will just be that same URL if it finished loading and continued to
     * the next step. If the step was a JS script, the corresponding item in the result array will
     * be the result returned to {@link Script.Interface#onCommandDone(String)} when it is called
     * by the script (Value can be a string if the JS script passed a string or null if the JS script
     * passed null.
     *
     * If something went wrong in the middle of the scripter, the number of items in the result
     * array can be less than the number of steps in the scripter. The last item in the result array
     * will be the error that occured on the corresponding step in the scripter. No steps after that
     * will execute and whatever results were accumulated till that point will be returned.
     *
     * @param id id given to the Scripter when it was created using {@link #spawnWebScripter(String, String)}
     * @param scripterString A stringified JSON array of steps as described above
     * @param success id of the success callback when execution finishes. Arguments are
     *                1. a stringified JSON array of results as defined above
     * @param error id of the error callback. Arguments are
     *              1. String version of the Exception.
     */
    @JavascriptInterface
    public void executeScripter(String id, String scripterString, String success, String error) {
        try {
            WebScripter webScripter = webScripters.get(id);
            Script script = makeScripter(scripterString);
            webScripter.executeScript(script, (results) -> {
                JSONArray resultArray = new JSONArray();
                try {
                    for (String result : results) {
                        resultArray.put(result);
                    }
                } catch (Exception e) {
                    Log.e("makeResultArray", "Exception", e);
                }

                callback(success, resultArray);
            });
        } catch (Exception e) {
            Log.e("executeScripter", "Exception", e);
            callback(error, e);
        }
    }

    /**
     * Used to cancel a scripter that was started using {@link #executeScripter(String, String, String, String)}
     * and hasn't finished yet
     *
     * @param id id given to the Scripter when it was created using {@link #spawnWebScripter(String, String)}
     */
    @JavascriptInterface
    public void cancelScripterExecution(String id) {
        WebScripter webScripter = webScripters.get(id);
        webScripter.cancel();
    }

    /**
     * When a Web Scripter is created, it is not made visible on the UI. Use this method to make
     * it visible. (It will take up the whole screen)
     *
     * @param id id given to the Scripter when it was created using {@link #spawnWebScripter(String, String)}
     */
    @JavascriptInterface
    public void showScripter(String id) {
        if(visibleScripter != null) {
            if(visibleScripter.equals(id)) {
                return;
            } else {
                hideScripter(visibleScripter);
            }
        }

        WebScripter scripter = webScripters.get(id);
        if (scripter != null) {
            runOnUiThread(() -> {
                FrameLayout frameLayout = findViewById(R.id.viewer);
                frameLayout.getChildAt(0);
                frameLayout.addView(scripter.getWebView());
                frameLayout.setVisibility(View.VISIBLE);
                visibleScripter = id;
            });
        }
    }

    /**
     * Use this method to hide a Web Scripter that was made visible using {@link #showScripter(String)}
     *
     * @param id id given to the Scripter when it was created using {@link #spawnWebScripter(String, String)}
     */
    @JavascriptInterface
    public void hideScripter(String id) {
        runOnUiThread(() -> {
            try {
                visibleScripter = null;
                WebScripter scripter = webScripters.get(id);
                FrameLayout frameLayout = findViewById(R.id.viewer);
                frameLayout.removeView(scripter.getWebView());
                frameLayout.setVisibility(View.GONE);
            } catch (Exception e) {/*Ignored*/}
        });
    }

    /**
     * Used to check if the device has security features for securely encrypting and decrypting
     * data using the OS Key Store.
     *
     * @return An integer of the following values:
     *          -1 if the device is secure and has the option for secure encryption
     *          0 if some unknown Exception occured while trying to check
     *          Any of the numbers from {@link EncryptionException} for known errors. See the
     *              corresponding messages for each error code in {@link EncryptionException#getMessage(int)}
     */
    @JavascriptInterface
    public int isDeviceSecure() {
        try {
            EncryptionHelper.checkDeviceAuthentication(this);
            return -1;
        } catch (EncryptionException e) {
            return e.getErrorCode();
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * Check if the user has been authenticated recently using their lock screen
     *
     * @return a boolean representing if the user has recently been authenticated. Also returns
     *  false if user authentication is not supported on the device (which can be found out using
     *  {@link #isDeviceSecure()}
     */
    @JavascriptInterface
    public boolean isUserAuthenticated() {
        return AuthenticationHelper.isUserAuthenticated(this);
    }

    /**
     * Use the device's lock screen to authenticate a user.
     *
     * @param success id representing a callback for success. Callback takes no arguments
     * @param error id representing a callback for an error. Arguments are:
     *              1. An error Response JSON (see {@link #makeErrorResponse(Exception)}
     */
    @JavascriptInterface
    public void authenticateUser(String success, String error) {
        AuthenticationHelper.authenticateUser(this, new Listener<Integer>() {
            @Override
            public void on(Integer result) {
                if(result == RESULT_CANCELED) {
                    callback(error, makeErrorResponse(
                            new EncryptionException(EncryptionException.ERROR_AUTHENTICATION_FAILED))
                            .toString());
                } else {
                    callback(success);
                }
            }

            @Override
            public void error(Exception e) {
                Log.e("authenticateUser", "Authentication exception", e);
                callback(error, e);
            }
        });
    }

    /**
     * Securely encrypts a given data using the Android Key Store (only supported on Android 6.0+).
     * A key for the given key name is created in the Key Store and used to encrypt the data. Once
     * a key is used for encrypting do not use the same key name for encrypting a different piece of
     * data as that will invalidate the Key created the previous time making that data
     * un-decryptable. Only use the same key name again if you are sure you want to previously
     * encrypted data to be invalidated and lost.
     *
     * @param data The string to be encrypted
     * @param keyName The alias to be used as a reference to the Key that will be generated and stored
     *                securely in the Android Key Store
     * @param success id representing a callback for successful encryption. Callback arguments are:
     *                1. The encrypted string
     * @param error id representing a callback for an unsuccessful encryption. Arguments are:
     *              1. An error Response JSON (see {@link #makeErrorResponse(Exception)}
     * @param authorized If true, the key will require user authentication before it can be used
     *                   making it more secure. If false, the key security will be restricted to
     *                   this app. (Not secure on rooted devices)
     */
    @JavascriptInterface
    public void secureEncrypt(String data, String keyName, String success, String error, boolean authorized) {
        EncryptionHelper encryptionHelper = new EncryptionHelper(this);
        Listener<String> listener = new Listener<String>() {
            @Override
            public void on(String result) {
                callback(success, result);
            }

            @Override
            public void error(Exception e) {
                callback(error, makeErrorResponse(e).toString());
            }
        };

        if(authorized) {
            encryptionHelper.encryptAuthenticated(keyName, data, listener);
        } else {
            encryptionHelper.encrypt(keyName, data, listener);
        }
    }

    /**
     * Securely decrypts a given data using the Key generated and stored in the Android Key Store
     * using {@link #secureEncrypt(String, String, String, String, boolean)} (only supported on Android 6.0+).
     *
     * @param data The string to be decrypted
     * @param keyName The alias to be used as a reference to the Key that will be generated and stored
     *                securely in the Android Key Store
     * @param success id representing a callback for successful decryption. Callback arguments are:
     *                1. The decrypted string
     * @param error id representing a callback for an unsuccessful decryption. Arguments are:
     *              1. An error Response JSON (see {@link #makeErrorResponse(Exception)}
     * @param authorized If the data was encrypted by passing `authorized = true` in {@link #secureEncrypt(String, String, String, String, boolean)}
     *                   then pass true here. Otherwise pass false.
     */
    @JavascriptInterface
    public void secureDecrypt(String data, String keyName, String success, String error, boolean authorized) {
        EncryptionHelper encryptionHelper = new EncryptionHelper(this);
        Listener<String> listener = new Listener<String>() {
            @Override
            public void on(String result) {
                callback(success, result);
            }

            @Override
            public void error(Exception e) {
                try {
                    JSONObject errorResponse = new JSONObject();
                    int errorCode;
                    if(e instanceof EncryptionException) {
                        errorCode = ((EncryptionException) e).getErrorCode();
                    } else {
                        errorCode = 0;
                    }
                    errorResponse.put("errorCode", errorCode);
                    errorResponse.put("errorMessage", EncryptionException.getMessage(errorCode));
                    callback(error, errorResponse);
                } catch (JSONException e1) {
                    Log.e("secureEncrypt","Error exception",  e);
                }
            }
        };

        if(authorized) {
            encryptionHelper.decryptAuthenticated(keyName, data, listener);
        } else {
            encryptionHelper.decrypt(keyName, data, listener);
        }
    }

    /**
     * Delete a key that was previously generated by {@link #secureEncrypt(String, String, String, String, boolean)}
     * to encrypt some data.
     *
     * @param keyName The key alias used in encryption using {@link #secureEncrypt(String, String, String, String, boolean)}
     */
    @JavascriptInterface
    public void deleteSecureKey(String keyName) {
        EncryptionHelper helper = new EncryptionHelper(this);
        helper.deleteKey(keyName);
    }

    /**
     * Store a String key value pair in SharedPreferences
     *
     * @param key Key to use for SharedPreferences
     * @param value String value that will be stored in SharedPreferences
     */
    @JavascriptInterface
    public void storeData(String key, String value) {
        Storage.store(this, key, value);
    }

    /**
     * Get a String value stored in SharedPreferences
     * @param key Key used when storing the value in SharedPreferences
     * @return Returns the stored String value or null if not found.
     */
    @Nullable
    @JavascriptInterface
    public String getData(String key) {
        return Storage.get(this, key);
    }

    /**
     * Delete a key value pair that may be stored in SharedPreferences
     * @param key Key of the key value pair stored in SharedPreferences
     */
    @JavascriptInterface
    public void clearData(String key) {
        Storage.clear(this, key);
    }


    /**
     * Fetch SMSs from the Inbox that have a delivery date newer than the one passed. This requires
     * the user to provide SMS permission. If SMS permission is not granted it will fail
     *
     * @param newerThan Time stamp in milliseconds that the fetched SMSs should be newer than
     * @param callback id representing the callback function. Arguments are:
     *                 1. A JSON array of SMS objects where each object has the following format:
     *                      {
     *                          from: "The from address as a string",
     *                          date: "A number of the sms date in milliseconds time stamp form",
     *                          body: "The sms body as a string"
     *                      }
     *                    OR in case the User did not provide SMS Read permission, the argument will
     *                    be the string "SMS_PERMISSION_DENIED"
     */
    @JavascriptInterface
    public void getSms(long newerThan, String callback) {
        if(!SmsReader.hasSmsPermission(this)) {
            smsCallback = callback;
            smsNewerThan = newerThan;
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.READ_SMS}, SMS_REQUEST_CODE);
        } else {
            SmsReader.getSms(this, newerThan, new Listener<List<SmsReader.Sms>>() {
                @Override
                public void on(List<SmsReader.Sms> result) {
                    try {
                        JSONArray smsArray = new JSONArray();
                        for (SmsReader.Sms sms : result) {
                            JSONObject smsObj = new JSONObject();
                            smsObj.put("from", sms.from);
                            smsObj.put("date", sms.date);
                            smsObj.put("body", sms.body);
                            smsArray.put(smsObj);
                        }
                        callback(callback, smsArray);
                    } catch (Exception e) {
                        Log.e("getSms", "Exception in `on`", e);
                    }
                }

                @Override
                public void error(Exception e) {
                    callback(callback, e);
                }
            });
        }
    }

    /**
     * Exits the application
     */
    @JavascriptInterface
    public void exit() {
        finish();
    }


    private Script makeScripter(String scripterString) throws JSONException {
        JSONArray steps = new JSONArray(scripterString);
        Script.StepsBuilder builder = new Script.StepsBuilder();

        for(int i = 0; i < steps.length(); i++) {
            JSONObject step = steps.getJSONObject(i);
            if(step.getString("type").toLowerCase().equals("js")) {
                builder.addJsStep(step.getString("command"));
            } else {
                builder.addUrlStep(step.getString("command"));
            }
        }

        return builder.build();
    }


    private JSONObject makeErrorResponse(Exception e) {
        try {
            JSONObject errorResponse = new JSONObject();
            int errorCode;
            String errorMessage;
            if(e instanceof EncryptionException) {
                errorCode = ((EncryptionException) e).getErrorCode();
                errorMessage = EncryptionException.getMessage(errorCode);
            } else {
                errorCode = 0;
                errorMessage = e.toString();
            }
            errorResponse.put("errorCode", errorCode);
            errorResponse.put("errorMessage", errorMessage);
            return errorResponse;
        } catch (JSONException e1) {
            Log.e("makeErrorResponse","Error exception",  e);
            return new JSONObject();
        }
    }


    private void callback(String callbackName, Object ...arguments) {
        try {
            JSONArray args = new JSONArray();
            for(Object argument : arguments) {
                args.put(argument);
            }


            String command =
                    "try{" +
                    "   var arguments = JSON.parse(atob('%s'));" +
                    "   window.InterfaceCallbacks['%s'].apply(window, arguments);" +
                    "} catch(error) {" +
                    "   console.error(error);" +
                    "}";
            runOnUiThread(() ->
                uiView.evaluateJavascript(String.format(command,
                        Base64.encodeToString(args.toString().getBytes(), Base64.NO_WRAP), callbackName), null)
            );
        } catch (Exception e) {
            Log.e("callback", "Fatal exception", e);
            throw new RuntimeException(e);
        }
    }

    @Override
    public void onBackPressed() {
        callback("onBackPressed");
    }

    @Override
    protected void onPause() {
        super.onPause();

        if(!isFinishing()) {
            callback("onPause");
        } else {
            uiView.destroy();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        callback("onResume");
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if(requestCode == SMS_REQUEST_CODE) {
            if(permissions.length > 0 && permissions[0].equals(Manifest.permission.READ_SMS)
                    && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                getSms(smsNewerThan, smsCallback);
            } else {
                callback(smsCallback, "SMS_PERMISSION_DENIED");
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if(requestCode == AUTH_REQUEST_CODE) {
            this.authListener.on(resultCode);
        }
    }
}
