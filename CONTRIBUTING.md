# Contributing to AmazingUltraTV

Thanks for helping. Bug reports, TV compatibility reports, themes, launcher features and translations are all welcome. By taking part you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Set up

Follow [Setup on Windows](README.md#setup-on-windows) in the README. Before opening a pull request, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build.ps1
launcher\gradlew.bat -p launcher test
powershell -ExecutionPolicy Bypass -File scripts\check-branding.ps1
```

CI runs the same build, tests and branding check on every pull request.

## How this repo relates to CleanYourTV

`launcher/` and `themes/` come from [CleanYourTV](https://github.com/Gathin23/cleanyourtv). We keep pulling in its improvements (see [UPSTREAM.md](UPSTREAM.md)), and that only stays painless if our changes to its files are small and easy to find:

- **Put new behaviour in new files and classes** wherever you can, rather than growing CleanYourTV's.
- **When you must change a CleanYourTV file, keep the edit minimal** and mark it with an `AmazingUltraTV:` comment, so a future sync conflict is easy to spot.
- **Don't rename or move inherited code.** The Java package `com.gathin.tvhome` stays as it is. The app's own identity lives in `launcher/gradle.properties` and the string resources.
- **User-visible text says AmazingUltraTV**, never CleanYourTV. `scripts/check-branding.ps1` enforces this.

Upstream syncs are done by maintainers, following [How to sync](UPSTREAM.md#how-to-sync). This project only pulls from CleanYourTV; it doesn't send changes back. Never run `git push --all` or `git push --mirror` in a clone that has the `upstream` remote: they would publish CleanYourTV's fetched refs to this repo.

## Report your TV

Tried AmazingUltraTV on a TV we haven't listed? Open a **TV compatibility report** issue with the brand and model, whether it runs Google TV or Android TV, the Android version, and what worked and what didn't.

## Pull requests

- One topic per pull request, with a clear description of what changed and why.
- CI must be green: build, unit tests and the branding check.
- Say how you tested it, and on which TV if it touches the launcher or the scripts. Screenshots help for anything visual.
- Never commit personal data: no TV IP addresses, network names, `backups/` folders or local paths. The scripts read the TV address from `-TvHost` or the `AUT_TV_HOST` environment variable for exactly this reason.

Security problems go through [SECURITY.md](SECURITY.md), not public issues.
