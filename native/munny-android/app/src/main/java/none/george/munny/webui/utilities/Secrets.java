package none.george.munny.webui.utilities;

import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;

import org.json.JSONObject;

import java.security.KeyStore;
import java.security.UnrecoverableKeyException;
import java.security.spec.AlgorithmParameterSpec;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

/**
 * Created by george.varghese on 08/09/18.
 */

public class Secrets {
    private static final int KEY_DURATION_SEC = 30;
    private static final String TRANSFORM = "AES/GCM/NoPadding";

    public static SecretKey generateKey(String keyAlias, boolean userAuthRequired, int userAuthValidSeconds) throws Exception {
        KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");

         KeyGenParameterSpec.Builder keyBuilder =
                 new KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE);

        if(userAuthRequired) {
            keyBuilder.setUserAuthenticationRequired(true);
            keyBuilder.setUserAuthenticationValidityDurationSeconds(userAuthValidSeconds);
        }

        KeyGenParameterSpec spec = keyBuilder.build();

        keyGenerator.init(spec);
        return keyGenerator.generateKey();
    }

    private static SecretKey getSecretKey(String keyAlias, boolean isForEncryption) throws Exception {
        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);

        KeyStore.Entry entry;
        entry = keyStore.getEntry(keyAlias, null);
        SecretKey secretKey;

        if(entry == null) {
            throw new IllegalArgumentException("No existing key for alias " + keyAlias);
        } else {
            KeyStore.SecretKeyEntry secretKeyEntry = (KeyStore.SecretKeyEntry) entry;
            secretKey = secretKeyEntry.getSecretKey();
        }

        return secretKey;
    }

    public static String encrypt(String keyAlias, String data) throws Exception {
        SecretKey secretKey = getSecretKey(keyAlias, true);

        Cipher cipher = Cipher.getInstance(TRANSFORM);
        cipher.init(Cipher.ENCRYPT_MODE, secretKey);

        byte[] encryptionIv = cipher.getIV();
        byte[] cipherBytes = cipher.doFinal(data.getBytes("UTF-8"));
        String cipherText = Base64.encodeToString(cipherBytes, Base64.NO_WRAP);
        String ivText = Base64.encodeToString(encryptionIv, Base64.NO_WRAP);

        return ivText + "_" + cipherText;
    }

    public static String decrypt(String keyAlias, String cipherString) throws Exception {
        SecretKey secretKey = getSecretKey(keyAlias, false);

        String ivText = cipherString.split("_")[0];
        String cipherText = cipherString.split("_")[1];
        byte[] cipherBytes = Base64.decode(cipherText, Base64.NO_WRAP);
        byte[] iv = Base64.decode(ivText, Base64.NO_WRAP);

        Cipher cipher = Cipher.getInstance(TRANSFORM);
        cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(128, iv));
        byte[] decryptedBytes = cipher.doFinal(cipherBytes);

        return new String(decryptedBytes, "UTF-8");
    }
}
