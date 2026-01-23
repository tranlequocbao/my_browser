# Browser Features Walkthrough

I have implemented tabbed browsing, smart search, history management, and now a password manager.

## Changes

### Password Manager
-   **`app/credential_manager.vala`**: Helper class to store and retrieve passwords using `libsecret`.
-   **`app/autofill.js`**: JavaScript that:
    -   Detects form submissions and extracts credentials.
    -   Exposes `window.fillCredentials(user, pass)` to autofill forms.
-   **`app/window.vala`**:
    -   Injects `autofill.js` into every page.
    -   Prompts the user to save passwords when a login is detected.
    -   Automatically fills passwords on page load if credentials exist.
-   **Dependencies**: Added `libsecret-1`.

### Bug Fixes
-   **History Dialog**: Fixed Gtk-WARNINGs by escaping markup in history items.

## Verification Results

### compilation
-   Ran `meson compile -C build` successfully (with some deprecation warnings).

### Manual Verification Required
Please verify the following:
1.  **Launch**: Run `meson install -C build && com.example.my_browser`.
2.  **Save Password**:
    -   Go to a login page (e.g., `https://the-internet.herokuapp.com/login`).
    -   Enter username/password and log in.
    -   A dialog "Save Password?" should appear. Click "Yes".
3.  **Autofill**:
    -   Refresh the page or logout and return to the login page.
    -   The username and password fields should be automatically filled.
4.  **History**: Check the history dialog to ensure no markup warnings appear in the terminal.
