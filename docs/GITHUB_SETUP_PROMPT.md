# GitHub Repository Setup Prompt

Copy and paste the prompt below into a new chat session to have an agent create a new public repository for AltWisprFlow and push the code.

---

## The Prompt

I want to publish my application, **AltWisprFlow**, to a new **public repository** on my GitHub account.

### Context:

- **Application Name:** AltWisprFlow
- **Project Type:** macOS Dictation App (Swift/SwiftUI/AppKit)
- **Local State:** The project is already a git repository but has **no remote** configured.
- **Goal:** Create the repository on GitHub, set up a professional project structure, and perform the initial push.

### Tasks for this Session:

1.  **Verify GitHub Authentication:** Check if the `gh` CLI is installed and authenticated to my account.
2.  **Create Public Repository:** Use `gh repo create altwisprflow --public` to create the repository on my GitHub account.
3.  **Configure Remote:** Add the newly created repository as the `origin` remote.
4.  **Prepare for Release:**
    - I have already updated `.gitignore` to exclude build artifacts, logs, and temporary test scripts.
    - I have scrubbed hardcoded test keys from the local working directory.
    - Review `README.md` and ensure it accurately reflects the current features (AssemblyAI v3, Auto-Paste, Secure Keychain storage).
5.  **Initial Push:** Push the `main` branch to GitHub.
6.  **Verify:** Confirm the repository is live and all files are correctly uploaded.

### Safety Note:

Ensure no sensitive debug logs or temporary test scripts (like `test_assemblyai.py`) are pushed if they contain hardcoded keys. Scrub any hardcoded keys from the history if necessary before the first push.
