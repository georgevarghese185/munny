package none.george.munny.webui;

import android.Manifest;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
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
import none.george.munny.webui.utilities.SmsReader;

public class WebUIActivity extends AppCompatActivity {
    private WebView uiView;
    private Map<String, WebScripter> webScripters;
    private int SMS_REQUEST_CODE = 1;
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
        uiView = WebScripter.newWebView(this);
        uiView.addJavascriptInterface(this, "Interface");
        uiView.loadUrl(getString(R.string.web_ui_source));
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
    public void executeScripter(String id, String scripterString, String callback) {
        try {
            WebScripter webScripter = webScripters.get(id);
            Script script = makeScripter(scripterString);
            webScripter.executeScript(script, (result) ->
                    callback(callback, makeResultArray(result).toString())
            );
        } catch (Exception e) {
            Log.e("executeScripter", "Exception", e);
            callback(callback, e.toString());
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
    private void getSms(long newerThan, String callback) {
        if(!SmsReader.hasSmsPermission(this)) {
            smsCallback = callback;
            smsNewerThan = newerThan;
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.READ_SMS}, SMS_REQUEST_CODE);
        } else {
            SmsReader.getSms(this, newerThan, new Listener<List<String>>() {
                @Override
                public void on(List<String> result) {
                    try {
                        JSONArray smsArray = new JSONArray();
                        for (String sms : result) {
                            smsArray.put("'" + sms + "'");
                        }
                        callback(callback, smsArray.toString());
                    } catch (Exception e) {
                        Log.e("getSms", "Exception in `on`", e);
                    }
                }

                @Override
                public void error(Exception e) {
                    callback(callback, e.toString());
                }
            });
        }
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

    private JSONArray makeResultArray(List<String> results) {
        JSONArray jsonArray = new JSONArray();
        try {
            for(String result : results) {
                jsonArray.put(result);
            }
        } catch (Exception e) {
            Log.e("makeResultArray", "Exception", e);
        }

        return jsonArray;
    }


    private void callback(String callbackName, String ...arguments) {
        StringJoiner args = new StringJoiner(", ", "[", "]");
        for(String argument : arguments) {
            args.add(argument);
        }

        String command =
                "try{" +
                "   window.InterfaceCallbacks[%s].apply(window, %s);" +
                "} catch(error) {" +
                "   console.error(error);" +
                "}";

        uiView.evaluateJavascript(String.format(command, callbackName, args.toString()), null);
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
            if(permissions.length > 1 && permissions[0].equals(Manifest.permission.READ_SMS)
                    && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                getSms(smsNewerThan, smsCallback);
            } else {
                callback(smsCallback, "'" + "SMS_PERMISSION_DENIED" + "'");
            }
        }
    }
}
