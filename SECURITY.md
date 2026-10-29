# Security

AmazingUltraTV runs as the home screen on people's TVs, and its scripts control those TVs over ADB, so a security bug here can reach someone's living room. Please report anything you find privately, not in a public issue.

## How to report

Use GitHub's private vulnerability reporting: open [Report a vulnerability](https://github.com/aysllanferreira/AmazingUltraTV/security/advisories/new) (the **Security** tab of this repo). Only the maintainer sees the report.

Please include:

- what is affected: the launcher app, a script in `scripts/`, or a theme;
- the steps to reproduce it, and the TV model and Android version if it matters;
- what an attacker could do with it.

You'll get an answer as soon as possible. Once a fix is out, you'll be credited in the release notes unless you'd rather not be.

## What's in scope

- The launcher app (`launcher/`), for example its exported activities, content provider, accessibility services and anything that could open apps or change settings unexpectedly.
- The PowerShell scripts (`scripts/`), for example anything that could change the wrong device, run unintended commands or leak data.

Problems in CleanYourTV's own code are also welcome here if they affect AmazingUltraTV. The upstream project has its own security policy for its other tools.

## Supported versions

Fixes go into the latest version on `main`. Please check that the problem still happens there.
