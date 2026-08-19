package cl.ufro.medhelp.exception;

import java.util.Map;

public class ContactValidationException extends RuntimeException {
    private final Map<String, String[]> errors;

    public ContactValidationException(Map<String, String[]> errors) {
        this.errors = errors;
    }

    public Map<String, String[]> getErrors() {
        return errors;
    }
}
