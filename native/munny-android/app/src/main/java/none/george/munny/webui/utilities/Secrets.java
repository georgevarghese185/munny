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

    private static SecretKey generateKey(String keyAlias) throws Exception {
        KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");

        KeyGenParameterSpec spec = new KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUserAuthenticationRequired(true)
                .setUserAuthenticationValidityDurationSeconds(KEY_DURATION_SEC)
                .build();

        keyGenerator.init(spec);
        return keyGenerator.generateKey();
    }

    private static SecretKey getSecretKey(String keyAlias, boolean isForEncryption) throws Exception {
        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);

        KeyStore.Entry entry;
        try {
            entry = keyStore.getEntry(keyAlias, null);
        } catch (UnrecoverableKeyException e) {
            entry = null;
        }
        SecretKey secretKey;
        if(entry == null && !isForEncryption) {
            throw new IllegalArgumentException("No existing key for alias " + keyAlias);
        } else if(entry == null) {
            secretKey = generateKey(keyAlias);
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

        JSONObject cipherObject = new JSONObject();
        cipherObject.put("cipherText", cipherText);
        cipherObject.put("ivText", ivText);

        return cipherObject.toString();
    }

    public static String decrypt(String keyAlias, String cipherObjectString) throws Exception {
        JSONObject cipherObject = new JSONObject(cipherObjectString);
        String cipherText = cipherObject.getString("cipherText");
        String ivText = cipherObject.getString("ivText");
        byte[] cipherBytes = Base64.decode(cipherText, Base64.NO_WRAP);
        byte[] iv = Base64.decode(ivText, Base64.NO_WRAP);

        SecretKey secretKey = getSecretKey(keyAlias, false);

        Cipher cipher = Cipher.getInstance(TRANSFORM);
        cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(128, iv));
        byte[] decryptedBytes = cipher.doFinal(cipherBytes);

        return new String(decryptedBytes, "UTF-8");
    }
}
