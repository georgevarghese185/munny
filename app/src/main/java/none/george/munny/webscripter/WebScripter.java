package none.george.munny.webscripter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.view.ViewGroup;
import android.webkit.WebView;

public class WebScripter {
    private WebView webView;
    private Script script;


    public WebScripter(Context context) {
        this.webView = newWebView(context);
    }

    @SuppressLint("SetJavaScriptEnabled")
    public static WebView newWebView(Context context) {
        WebView webView = new WebView(context);
        ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        webView.setLayoutParams(new WebView.LayoutParams(layoutParams));
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
}
