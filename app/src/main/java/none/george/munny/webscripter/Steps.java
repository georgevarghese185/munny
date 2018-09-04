package none.george.munny.webscripter;

import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.support.annotation.Nullable;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.util.ArrayList;
import java.util.List;

public class Steps {
    public static final String INTERFACE_NAME = "StepInterface";

    private List<Step> steps;
    private WebView webView;
    private CompleteListener completeListener;
    private int currentStep;

    public interface CompleteListener {
        void onComplete(@Nullable String result);
    }

    private Steps(List<Step> steps) {
        this.steps = steps;
    }


    public void execute(WebView webView, CompleteListener completeListener) {
        this.webView = webView;
        Client client = new Client();
        Interface _interface = new Interface();
        this.completeListener = completeListener;

        this.webView.setWebViewClient(client);
        this.webView.addJavascriptInterface(_interface, INTERFACE_NAME);

        executeStep(0, null);
    }

    private void executeStep(int stepNumber, @Nullable String result) {
        if(stepNumber < steps.size()) {
            currentStep = stepNumber;
            steps.get(stepNumber).execute(webView);
        } else {
            webView.removeJavascriptInterface(INTERFACE_NAME);
            webView.setWebViewClient(null);
            runOnUiThread(() -> completeListener.onComplete(result));
        }
    }


    private static class Step {
        private String command;
        private boolean isUrlCommand;

        Step(String command, boolean isUrlCommand) {
            this.command = command;
            this.isUrlCommand = isUrlCommand;
        }

        void execute(WebView webView) {
            runOnUiThread(() -> {
                if(isUrlCommand) {
                    webView.loadUrl(command);
                } else {
                    webView.evaluateJavascript(command, null);
                }
            });
        }
    }


    private class Client extends WebViewClient{

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);
            executeStep(currentStep + 1, null);
        }
    }


    private class Interface {
        @JavascriptInterface
        public void onCommandDone() {
            executeStep(currentStep + 1, null);
        }

        @JavascriptInterface
        public void onCommandDone(String result) {
            executeStep(currentStep + 1, result);
        }
    }


    public static class StepsBuilder {
        private ArrayList<Step> steps;

        public StepsBuilder(String startUrl) {
            steps = new ArrayList<>();
            Step start = new Step(startUrl, true);
            steps.add(start);
        }

        public StepsBuilder addUrlStep(String url) {
            try {
                steps.add(new Step(url, true));
                return this;
            } catch (Exception e) {
                return null;
            }
        }

        public StepsBuilder addJsStep(String jsCommand) {
            try {
                steps.add(new Step(jsCommand, false));
                return this;
            } catch (Exception e) {
                return null;
            }
        }

        public Steps build() {
            return new Steps(this.steps);
        }
    }

    private static void runOnUiThread(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }
}
