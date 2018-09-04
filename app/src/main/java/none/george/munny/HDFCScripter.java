package none.george.munny;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.webkit.WebView;
import android.widget.Toast;

import none.george.munny.webscripter.Code;
import none.george.munny.webscripter.Steps;

public class HDFCScripter {
    public static final String NETBANKING_URL = "https://netbanking.hdfcbank.com/netbanking/";
    public static final String SCRIPT_FILE = "hdfc/scripts.js";

    private Code enterUsername;
    private Code enterPasswordAndLogin;
    private Code isOtpPage;
    private Code fireOtp;

    public HDFCScripter(Context context) {
        enterUsername = loadSnippet(context, "submit_username");
        enterPasswordAndLogin = loadSnippet(context, "submit_password_login");
        isOtpPage = loadSnippet(context, "is_otp_page");
        fireOtp = loadSnippet(context, "fire_otp");
    }

    public static Code loadSnippet(Context context, String snippetName) {
        return new Code(context, SCRIPT_FILE, snippetName);
    }

    public void getBalance(Context context, WebView webView, String username, String password) {
        new Handler(Looper.getMainLooper()).post(() -> {
            Steps loginScript = new Steps.StepsBuilder(NETBANKING_URL)
                    .addJsStep(enterUsername.args("username", username).toString())
                    .addJsStep(enterPasswordAndLogin.args("password", password).toString())
                    .addJsStep(isOtpPage.toString())
                    .build();

            loginScript.execute(webView, (result) -> {
                if(result != null && result.equals("true")) {
                    Toast.makeText(context, "OTP", Toast.LENGTH_LONG).show();
                } else {
                    Toast.makeText(context, "NOT OTP", Toast.LENGTH_LONG).show();
                }
            });
        });
    }


}
