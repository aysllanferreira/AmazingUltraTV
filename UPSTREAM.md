# Upstream

AmazingUltraTV is built on [CleanYourTV](https://github.com/Gathin23/cleanyourtv) (formerly tv-vibehack) by Gathin, under the MIT licence. We take its launcher and themes and pull in its later improvements. The relationship is pull-only: nothing is sent back, and CleanYourTV's git history is not part of ours.

| | |
| --- | --- |
| Upstream | https://github.com/Gathin23/cleanyourtv.git |
| Synced paths | `launcher/`, `themes/`, `.gitattributes` |

Baseline: 42fe7b09d61fb9175cb03b8c659cd63c9c1dd9a4

The baseline is the upstream commit that the synced paths are based on. Our own changes sit on top of it. `scripts/sync-upstream.ps1` reads the line above, so keep its format.

## How to sync

1. Start from an up-to-date `main` with no uncommitted changes, on a new branch:

   ```powershell
   git switch -c sync-upstream main
   ```

2. Pull CleanYourTV's changes since the baseline, up to their latest `main` (or any branch or full commit sha):

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\sync-upstream.ps1 -To main
   ```

   The script:
   - fetches only that one upstream commit;
   - applies upstream's changes to the synced paths with a three-way merge, so our edits are kept;
   - updates the baseline and the history below, and stages everything.

   It also sets the `upstream` remote's push URL to `no_push`, so nothing can ever be pushed there.

3. If the script lists conflicts, fix those files (search for `<<<<<<<`) and `git add` them. Our edits to upstream files carry an `AmazingUltraTV:` comment, which makes them easy to spot.
4. Run `scripts\build.ps1` and `launcher\gradlew.bat test`, then `scripts\check-branding.ps1`. Commit with the message the script prints, and open a pull request.

Never run `git push --all` or `git push --mirror`: they would publish the fetched upstream refs to our repo.

## Sync history

Keep this section last; the sync script appends to it.

- 2026-10-29: first import of 42fe7b09d61fb9175cb03b8c659cd63c9c1dd9a4
