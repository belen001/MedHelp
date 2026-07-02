package cl.ufro.medhelp.exception;

import java.util.Map;

public class PasswordMismatchException extends RuntimeException {
    private final Map<String, String[]> errors;

    public PasswordMismatchException(Map<String, String[]> errors) {
        this.errors = errors;
    }

    public Map<String, String[]> getErrors() {
        return errors;
    }
}
