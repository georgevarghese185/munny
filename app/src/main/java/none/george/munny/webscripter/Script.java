package none.george.munny.webscripter;

import android.net.http.SslError;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.Nullable;
import android.webkit.JavascriptInterface;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Script {
    public static final String INTERFACE_NAME = "Interface";

    private List<Step> steps;
    private WebView webView;
    private CompleteListener completeListener;
    private int currentStep;
    private List<String> resultAccumulator;
    private boolean canceled = false;

    public interface CompleteListener {
        void onComplete(List<String> resultAccumulator);
    }

    private Script(List<Step> steps) {
        this.steps = steps;
        resultAccumulator = new ArrayList<>();
    }


    public void execute(WebView webView, CompleteListener completeListener) {
        this.webView = webView;
        Client client = new Client();
        Interface _interface = new Interface();
        this.completeListener = completeListener;

        this.webView.setWebViewClient(client);
        this.webView.addJavascriptInterface(_interface, INTERFACE_NAME);

        executeStep(0);
    }

    private void executeStep(int stepNumber) {
        if(stepNumber < steps.size() && !canceled) {
            currentStep = stepNumber;
            steps.get(stepNumber).execute(webView);
        } else {
            end();
        }
    }

    public void end() {
        canceled = true;
        runOnUiThread(() -> {
            webView.removeJavascriptInterface(INTERFACE_NAME);
            webView.setWebViewClient(null);
            completeListener.onComplete(resultAccumulator);
        });
    }

    private void accumulate(@Nullable String result) {
        resultAccumulator.add(result);
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
            accumulate(url);
            executeStep(currentStep + 1);
        }

        @Override
        public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
            super.onReceivedError(view, request, error);
            accumulate(error.toString());
            end();
        }

        @Override
        public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse errorResponse) {
            super.onReceivedHttpError(view, request, errorResponse);
            accumulate(writeErrorResponse(errorResponse).toString());
            end();
        }

        @Override
        public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
            super.onReceivedSslError(view, handler, error);
            accumulate( error.getPrimaryError() + ":" + error.getUrl());
            end();
        }
    }


    private class Interface {
        @JavascriptInterface
        public void onCommandDone(@Nullable String result) {
            accumulate(result);
            executeStep(currentStep + 1);
        }
    }


    public static class StepsBuilder {
        private ArrayList<Step> steps;

        public StepsBuilder(String startUrl) {
            steps = new ArrayList<>();
            Step start = new Step(startUrl, true);
            steps.add(start);
        }

        public StepsBuilder() {
            steps = new ArrayList<>();
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

        public Script build() {
            return new Script(this.steps);
        }
    }



    private static JSONObject writeErrorResponse(WebResourceResponse resourceError) {
        JSONObject error = new JSONObject();
        BufferedReader reader = null;
        try {
            error.put("encoding", resourceError.getEncoding());
            error.put("mime-type", resourceError.getMimeType());
            error.put("reason", resourceError.getReasonPhrase());
            error.put("code", resourceError.getStatusCode());

            JSONObject headers = new JSONObject();
            for(Map.Entry<String, String> entry : resourceError.getResponseHeaders().entrySet()) {
                headers.put(entry.getKey(), entry.getValue());
            }

            error.put("headers", headers);

            reader = new BufferedReader(new InputStreamReader(resourceError.getData()));
            StringBuilder errorData = new StringBuilder();
            String line;

            while((line = reader.readLine()) != null) {
                errorData.append(line);
            }

            error.put("data", errorData.toString());

            return error;
        } catch (Exception e) {
            HashMap<String, String> hashMap = new HashMap<>();
            hashMap.put("ERROR_RESPONSE_EXCEPTION", e.toString());
            hashMap.put("INCOMPLETE_ERROR_RESPONSE", error.toString());

            return error;
        } finally {
            if(reader != null) {
                try {
                    reader.close();
                } catch (Exception e) {/*Ignored*/}
            }
        }
    }

    private static void runOnUiThread(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }
}
