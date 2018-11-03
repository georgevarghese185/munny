package none.george.munny.webui.utilities.secrets;

import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.crypto.Cipher;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.biometrics.BiometricPrompt;
import androidx.fragment.app.FragmentActivity;
import none.george.munny.Listener;
import none.george.munny.webui.WebUIActivity;

import static none.george.munny.webui.WebUIActivity.AUTH_REQUEST_CODE;

public class AuthenticationHelper {

    public static void authenticateUser(WebUIActivity activity, Listener<Integer> listener) {
        try {
            KeyguardManager keyguardManager = (KeyguardManager) activity.getSystemService(Context.KEYGUARD_SERVICE);
            assert keyguardManager != null;
            Intent intent = keyguardManager.createConfirmDeviceCredentialIntent(null, null);
            activity.authListener = listener;
            activity.startActivityForResult(intent, AUTH_REQUEST_CODE);
        } catch (Exception e) {
            listener.error(e);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    public static void authenticateFingerprint(FragmentActivity activity, @Nullable Cipher cipher, Listener<Void> listener) {
        try {
            ExecutorService executorService = Executors.newSingleThreadExecutor();
            BiometricPrompt.AuthenticationCallback callback = new BiometricPrompt.AuthenticationCallback() {
                @Override
                public void onAuthenticationError(int errorCode, @NonNull CharSequence errString) {
                    executorService.shutdown();
                    switch (errorCode) {
                        case BiometricPrompt.ERROR_CANCELED:
                            listener.error(new EncryptionException(EncryptionException.ERROR_AUTHENTICATION_FAILED));
                            break;
                        case BiometricPrompt.ERROR_LOCKOUT:
                            listener.error(new EncryptionException(EncryptionException.ERROR_TOO_MANY_ATTEMPTS));
                    }
                    listener.error(new Exception(errString.toString()));
                }

                @Override
                public void onAuthenticationSucceeded(@NonNull BiometricPrompt.AuthenticationResult result) {
                    executorService.shutdown();
                    try {
                        listener.on(null);
                    } catch (Exception e) {
                        listener.error(e);
                    }
                }
            };

            BiometricPrompt prompt = new BiometricPrompt(activity, executorService, callback);
            BiometricPrompt.PromptInfo promptInfo = new BiometricPrompt.PromptInfo.Builder()
                    .setTitle("Authenticate this action")
                    .setNegativeButtonText("Cancel")
                    .build();

            prompt.authenticate(promptInfo, cipher == null? null : new BiometricPrompt.CryptoObject(cipher));
        } catch (Exception e) {
            listener.error(e);
        }
    }

    public static boolean isUserAuthenticated(Context context) {
        try {
            KeyguardManager keyguardManager = (KeyguardManager) context.getSystemService(Context.KEYGUARD_SERVICE);
            assert keyguardManager != null;
            return keyguardManager.isKeyguardLocked();
        } catch (Exception e) {
            Log.e("isUserAuthenticated", "Exception", e);
            return false;
        }
    }
}
