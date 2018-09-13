package none.george.munny.webui;

import android.Manifest;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.net.Uri;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.widget.FrameLayout;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import none.george.munny.BuildConfig;
import none.george.munny.java.util.StringJoiner;

import none.george.munny.Listener;
import none.george.munny.R;
import none.george.munny.webscripter.Script;
import none.george.munny.webscripter.WebScripter;
import none.george.munny.webui.utilities.Secrets;
import none.george.munny.webui.utilities.SmsReader;

public class WebUIActivity extends AppCompatActivity {
    private static final String START_URL = "file:///android_asset/index.html";

    private WebView uiView;
    private Map<String, WebScripter> webScripters;
    private int SMS_REQUEST_CODE = 1;
    private int AUTH_REQUEST_CODE = 2;
    private Listener<Integer> authListener;
    private String smsCallback;
    private long smsNewerThan;
    private String visibleScripter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_web_ui);

        if(BuildConfig.DEBUG) {
            WebView.setWebContentsDebuggingEnabled(true);
        }

        webScripters = new HashMap<>();
        uiView = WebScripter.setupWebView(findViewById(R.id.ui_web_view));
        uiView.setWebViewClient(new WebScripter.AssetClient());
        uiView.addJavascriptInterface(this, "__Native_Interface");
        uiView.loadUrl(START_URL);
    }

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

    @JavascriptInterface
    public void killScripter(String id) {
        WebScripter webScripter = webScripters.get(id);
        hideScripter(id);
        webScripter.kill();
        webScripters.remove(id);
    }


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

    @JavascriptInterface
    public void secureEncrypt(String data, String keyName, String success, String error) {
        authenticateUser(new Listener<Integer>() {
            @Override
            public void on(Integer result) {
                if(result == RESULT_CANCELED) {
                    callback(error, "Authentication failed");
                } else {
                    try {
                        String encrypted = Secrets.encrypt(keyName, data);
                        callback(success, encrypted);
                    } catch (Exception e) {
                        Log.e("secureEncrypt", "Exception while encrypting", e);
                        callback(error, e);
                    }
                }
            }

            @Override
            public void error(Exception e) {
                Log.e("secureEncrypt", "Exception while authenticating", e);
                callback(error, e);
            }
        });
    }

    @JavascriptInterface
    public void secureDecrypt(String data, String keyName, String authTitle, String authDescription,
                              String success, String error) {
        authenticateUser(new Listener<Integer>() {
            @Override
            public void on(Integer result) {
                if(result == RESULT_CANCELED) {
                    callback(error, "Authentication failed");
                } else {
                    try {
                        String encrypted = Secrets.decrypt(keyName, data);
                        callback(success, encrypted);
                    } catch (Exception e) {
                        Log.e("secureEncrypt", "Exception while encrypting", e);
                        callback(error, e);
                    }
                }
            }

            @Override
            public void error(Exception e) {
                Log.e("secureEncrypt", "Exception while authenticating", e);
                callback(error, e);
            }
        });
    }


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


    private void callback(String callbackName, Object ...arguments) {
        try {
            JSONArray args = new JSONArray();
            for(Object argument : arguments) {
                if(argument instanceof Integer || argument instanceof Double || argument instanceof Float
                        || argument instanceof JSONObject || argument instanceof JSONArray) {
                    args.put(argument);
                } else {
                    args.put("'" + argument.toString() + "'");
                }
            }


            String command =
                    "try{" +
                    "   var arguments = JSON.parse(decodeURIComponent('%s'));" +
                    "   window.InterfaceCallbacks['%s'].apply(window, arguments);" +
                    "} catch(error) {" +
                    "   console.error(error);" +
                    "}";
            runOnUiThread(() -> {
                try {
                    String argsString = URLEncoder.encode(args.toString(), "UTF-8");
                    uiView.evaluateJavascript(String.format(command, argsString, callbackName), null);
                } catch (Exception e) {
                    Log.e("callback", "Fatal exception", e);
                    throw new RuntimeException(e);
                }
            });
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
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
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

    private void authenticateUser(Listener<Integer> authListener) {
        KeyguardManager keyguardManager = (KeyguardManager) getSystemService(Context.KEYGUARD_SERVICE);
        assert keyguardManager != null;
        if(!keyguardManager.isDeviceSecure()) {
            authListener.error(new IllegalStateException("No screen lock"));
        } else {
            this.authListener = authListener;
            Intent intent = keyguardManager.createConfirmDeviceCredentialIntent(null, null);
            startActivityForResult(intent, AUTH_REQUEST_CODE);
        }
    }
}