package none.george.munny.webui.utilities.secrets;

import android.app.AlertDialog;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.security.keystore.UserNotAuthenticatedException;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import android.util.Base64;
import android.util.Log;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.MessageDigest;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

import androidx.core.hardware.fingerprint.FingerprintManagerCompat;
import none.george.munny.Listener;
import none.george.munny.webui.WebUIActivity;

import static android.app.Activity.RESULT_OK;

public class EncryptionHelper {
    public static final int USER_AUTH_VALID_SECONDS = 5;
    private static final String TRANSFORM = "AES/GCM/NoPadding";
    private static final String FALLBACK_KEYS_PREF_NAME = "encryption_util_fallback_keys";

    private WebUIActivity activity;


    public EncryptionHelper(WebUIActivity activity) {
        this.activity = activity;
    }

    public static void checkDeviceAuthentication(Context context) throws Exception {
        try {
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                KeyguardManager keyguardManager = (KeyguardManager) context.getSystemService(Context.KEYGUARD_SERVICE);
                assert keyguardManager != null;
                if(!keyguardManager.isDeviceSecure()) {
                    throw new EncryptionException(EncryptionException.ERROR_NO_SECURE_LOCK);
                }
            } else {
                throw new EncryptionException(EncryptionException.ERROR_AUTH_ENCRYPTION_NOT_SUPPORTED);
            }
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            Log.e("check device auth", "Exception", e);
            throw e;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private boolean hasFingerprints() {
        FingerprintManagerCompat fingerprintManager = FingerprintManagerCompat.from(activity);
        return fingerprintManager.hasEnrolledFingerprints();
    }


    @RequiresApi(api = Build.VERSION_CODES.M)
    public static void generateKey(String keyAlias, boolean userAuthenticated, boolean setValidity) throws Exception {
        KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
        KeyGenParameterSpec.Builder spec = new KeyGenParameterSpec.Builder(keyAlias,
                KeyProperties.PURPOSE_DECRYPT | KeyProperties.PURPOSE_ENCRYPT);

        spec.setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE);

        if(userAuthenticated) {
            spec.setUserAuthenticationRequired(true);
            if(setValidity) {
                spec.setUserAuthenticationValidityDurationSeconds(USER_AUTH_VALID_SECONDS);
            }
        }

        keyGenerator.init(spec.build());
        keyGenerator.generateKey();
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private static SecretKey getKey(String keyAlias, boolean authenticated) throws Exception {
        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);
        SecretKey key = (SecretKey) keyStore.getKey(keyAlias, null);

        if(key == null) {
            generateKey(keyAlias, authenticated, true);
            key = (SecretKey) keyStore.getKey(keyAlias, null);
        }

        return key;
    }

    private static Cipher getCipher(int mode, SecretKey key, @Nullable String ivString) throws Exception {
        Cipher cipher = Cipher.getInstance(TRANSFORM);
        if (mode == Cipher.ENCRYPT_MODE) {
            cipher.init(mode, key);
        } else {
            byte[] iv = Base64.decode(ivString, Base64.NO_WRAP);
            cipher.init(mode, key, new GCMParameterSpec(128, iv));
        }
        return cipher;
    }

    private static String getIvString(String data) {
        return data.split("_")[0];
    }

    private static String encrypt(String data, Cipher cipher) throws Exception {
        byte[] cipherBytes = cipher.doFinal(data.getBytes("UTF-8"));
        String cipherText = Base64.encodeToString(cipherBytes, Base64.NO_WRAP);
        String ivText = Base64.encodeToString(cipher.getIV(), Base64.NO_WRAP);

        return ivText + "_" + cipherText;
    }

    private static String decrypt(String cipherString, Cipher cipher) throws Exception {
        String cipherText = cipherString.split("_")[1];
        byte[] cipherBytes = Base64.decode(cipherText, Base64.NO_WRAP);
        byte[] decryptedBytes = cipher.doFinal(cipherBytes);

        return new String(decryptedBytes, "UTF-8");
    }



    public void encrypt(String keyAlias, String data, Listener<String> listener) {
        deleteKey(keyAlias);
        try {
            if(Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                throw new EncryptionException(EncryptionException.ERROR_AUTH_ENCRYPTION_NOT_SUPPORTED);
            } else {
                SecretKey key = getKey(keyAlias, false);
                Cipher cipher = getCipher(Cipher.ENCRYPT_MODE, key, null);
                listener.on(encrypt(data, cipher));
            }
        } catch (Exception e) {
            listener.error(e);
        }
    }


    public void encryptAuthenticated(String keyAlias, String data, Listener<String> listener) {
        deleteKey(keyAlias);
        try {
            if(Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                throw new EncryptionException(EncryptionException.ERROR_AUTH_ENCRYPTION_NOT_SUPPORTED);
            } else {
                SecretKey key = getKey(keyAlias, true);
                AuthenticationHelper.authenticateUser(activity, new Listener<Integer>() {
                    @Override
                    public void on(Integer result) {
                        if (result != RESULT_OK) {
                            listener.error(new EncryptionException(EncryptionException.ERROR_AUTHENTICATION_FAILED));
                        } else {
                            if (usesFallback(keyAlias)) {
                                fingerprintFallback(Cipher.ENCRYPT_MODE, keyAlias, data, listener);
                            } else {
                                encryptData(keyAlias, key, data, listener);
                            }
                        }
                    }

                    @Override
                    public void error(Exception e) {
                        listener.error(e);
                    }
                });
            }
        } catch (KeyStoreException e){
            setFallback(keyAlias, false);
            listener.error(e);
        } catch (Exception e) {
            listener.error(e);
        }
    }

    public void decrypt(String keyAlias, String data, Listener<String> listener) {
        try {
            if(Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                throw new EncryptionException(EncryptionException.ERROR_AUTH_ENCRYPTION_NOT_SUPPORTED);
            } else {
                SecretKey key = getKey(keyAlias, false);
                Cipher cipher = getCipher(Cipher.DECRYPT_MODE, key, getIvString(data));
                listener.on(decrypt(data, cipher));
            }
        } catch (Exception e) {
            listener.error(e);
        }
    }

    public void decryptAuthenticated(String keyAlias, String data, Listener<String> listener) {
        try {
            if(Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                throw new EncryptionException(EncryptionException.ERROR_AUTH_ENCRYPTION_NOT_SUPPORTED);
            } else {
                SecretKey key = getKey(keyAlias, true);
                if (usesFallback(keyAlias)) {
                    fingerprintFallback(Cipher.DECRYPT_MODE, keyAlias, data, listener);
                } else {
                    AuthenticationHelper.authenticateUser(activity, new Listener<Integer>() {
                        @Override
                        public void on(Integer result) {
                            if (result != RESULT_OK) {
                                listener.error(new EncryptionException(EncryptionException.ERROR_AUTHENTICATION_FAILED));
                            } else {
                                try {
                                    Cipher cipher = getCipher(Cipher.DECRYPT_MODE, key, getIvString(data));
                                    listener.on(decrypt(data, cipher));
                                } catch (Exception e) {
                                    listener.error(e);
                                }
                            }
                        }

                        @Override
                        public void error(Exception e) {
                            listener.error(e);
                        }
                    });
                }
            }
        } catch (Exception e) {
            listener.error(e);
        }
    }

    public void deleteKey(String keyAlias) {
        try {
            KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
            keyStore.load(null);
            keyStore.deleteEntry(keyAlias);
            setFallback(keyAlias, false);
        } catch (Exception e) {
            Log.e("deleteKey", "Exception while trying to delete a key", e);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private void encryptData(String keyAlias, SecretKey key, String data, Listener<String> listener) {
        try {
            Cipher cipher = getCipher(Cipher.ENCRYPT_MODE, key, null);
            String cipherString = encrypt(data, cipher);
            listener.on(cipherString);
        } catch (UserNotAuthenticatedException e) {
            if (hasFingerprints()) {
                proposeFingerprintFallback(keyAlias, data, listener);
            } else {
                listener.error(e);
            }
        } catch (Exception e) {
            listener.error(e);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private void proposeFingerprintFallback(String keyAlias, String data, Listener<String> listener) {
        AlertDialog.OnClickListener tryFallback = (d,w) -> {
            try {
                setFallback(keyAlias, true);
                generateKey(keyAlias, true, false);
                fingerprintFallback(Cipher.ENCRYPT_MODE, keyAlias, data, listener);
            } catch (Exception e) {
                listener.error(e);
            }
        };

        new AlertDialog.Builder(activity)
                .setTitle("Problem with Encryption")
                .setMessage("There was a problem trying to encrypt your data using your screen " +
                        "lock. This could be a known issue with some devices that have fingerprint " +
                        "lock enabled. Would you like to try a fallback encryption method? Note: " +
                        "the fallback method only supports fingerprint (no Pattern or PIN)")
                .setPositiveButton("Try Fallback", tryFallback)
                .setNegativeButton("Cancel", (dialog, which) -> listener.error(new Exception("Screen lock encryption failed")))
                .setOnCancelListener(v -> listener.error(new UserNotAuthenticatedException()))
                .create()
                .show();
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private void fingerprintFallback(int mode, String keyAlias, String data, Listener<String> listener) {
        try {
            SecretKey key = getKey(keyAlias, true);
            Cipher cipher;
            if(mode == Cipher.ENCRYPT_MODE) {
                cipher = getCipher(Cipher.ENCRYPT_MODE, key, null);
            } else {
                cipher = getCipher(Cipher.DECRYPT_MODE, key, getIvString(data));
            }

            AuthenticationHelper.authenticateFingerprint(activity, cipher, new Listener<Void>() {
                @Override
                public void on(Void result) {
                    try {
                        if(mode == Cipher.ENCRYPT_MODE) {
                            listener.on(encrypt(data, cipher));
                        } else {
                            listener.on(decrypt(data, cipher));
                        }
                    } catch (Exception e) {
                        listener.error(e);
                    }
                }

                @Override
                public void error(Exception e) {
                    listener.error(e);
                }
            });
        } catch (Exception e) {
            listener.error(e);
        }
    }

    public static String sha256(String s) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(s.getBytes(StandardCharsets.UTF_8));
            return Base64.encodeToString(hashBytes, Base64.NO_WRAP);
        } catch (Exception e) {
            Log.e("Encryption", "SHA256 exception", e);
            return null;
        }
    }

    private void setFallback(String keyName, boolean useFallback) {
        SharedPreferences preferences = activity.getSharedPreferences(FALLBACK_KEYS_PREF_NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = preferences.edit();
        if(useFallback) {
            editor.putBoolean(sha256(keyName), true);
        } else {
            editor.remove(sha256(keyName));
        }
        editor.apply();
    }

    private boolean usesFallback(String keyName) {
        SharedPreferences preferences = activity.getSharedPreferences(FALLBACK_KEYS_PREF_NAME, Context.MODE_PRIVATE);
        return preferences.contains(sha256(keyName));
    }
}
