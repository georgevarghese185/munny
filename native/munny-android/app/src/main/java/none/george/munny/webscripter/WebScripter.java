package none.george.munny.webscripter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.Nullable;
import android.view.ViewGroup;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.FileInputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import none.george.munny.BuildConfig;
import none.george.munny.R;

public class WebScripter {
    private WebView webView;
    private Script script;
    public static final String MAIN_SCRIPT_URL = "file:///android_asset/index.js";


    public WebScripter(Context context) {
        this.webView = newWebView(context);
    }

    @SuppressLint("SetJavaScriptEnabled")
    public static WebView newWebView(Context context) {
        WebView webView = new WebView(context);
        ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        webView.setLayoutParams(new WebView.LayoutParams(layoutParams));
        return setupWebView(webView);
    }

    @SuppressLint("SetJavaScriptEnabled")
    public static WebView setupWebView(WebView webView) {
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDatabaseEnabled(true);
        webView.setOverScrollMode(WebView.OVER_SCROLL_NEVER);
        return webView;
    }

    public WebView getWebView() {
        return webView;
    }

    public void executeScript(Script script, Script.CompleteListener completeListener) {
        this.script = script;
        new Handler(Looper.getMainLooper()).post(() ->
                script.execute(webView, (result) -> {
                    WebScripter.this.script = null;
                    completeListener.onComplete(result);
                }
        ));
    }

    public void kill() {
        new Handler(Looper.getMainLooper()).post(() -> {
            if(this.script != null) {
                script.end();
            }

            webView.destroy();
        });
    }

    public static class AssetClient extends WebViewClient {@Nullable
        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
            Context context = view.getContext();
            String url = request.getUrl().toString();
            try {
                if (url.matches("^file:///android_asset/.*")) {
                    String file = url.split("file:///android_asset/")[1];
                    InputStream inputStream;

                    if (BuildConfig.DEBUG) {
                        String debugRoot = context.getString(R.string.debug_url);
                        URL debugUrl = new URL(debugRoot + file);
                        HttpURLConnection connection = (HttpURLConnection) debugUrl.openConnection();
                        inputStream = connection.getInputStream();
                    } else {
                        inputStream = context.getAssets().open("app/" + file);
                    }

                    return new WebResourceResponse("text/javascript", "UTF-8", inputStream);
                } else {
                    return super.shouldInterceptRequest(view, request);
                }
            } catch (Exception e) {
                return super.shouldInterceptRequest(view, request);
            }
        }
    }
}
