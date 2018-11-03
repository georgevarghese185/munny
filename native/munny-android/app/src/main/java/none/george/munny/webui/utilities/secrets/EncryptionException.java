package none.george.munny.webui.utilities.secrets;

public class EncryptionException extends Exception {
    private int errorCode;

    public static final int ERROR_OTHER = 0;
    public static final int ERROR_NO_SECURE_LOCK = 1;
    public static final int ERROR_AUTH_ENCRYPTION_NOT_SUPPORTED = 2;
    public static final int ERROR_KEYS_INVALIDATED = 3;
    public static final int ERROR_AUTHENTICATION_FAILED = 4;
    public static final int ERROR_TOO_MANY_ATTEMPTS = 5;

    public EncryptionException(int errorCode) {
        super(new Exception(getMessage(errorCode)));
        this.errorCode = errorCode;
    }

    public static String getMessage(int errorCode) {
        switch (errorCode) {
            case ERROR_NO_SECURE_LOCK:
                return "No secure lock screen has been set";
            case ERROR_AUTH_ENCRYPTION_NOT_SUPPORTED:
                return "Device enabled encryption only available on Android 6.0+";
            case ERROR_KEYS_INVALIDATED:
                return "The phone lock screen has been changed and keys invalidated";
            case ERROR_AUTHENTICATION_FAILED:
                return "User authentication failed";
            case ERROR_TOO_MANY_ATTEMPTS:
                return "Too many failed attempts";
            default: return "Other error";
        }
    }

    public int getErrorCode() {
        return errorCode;
    }
}
