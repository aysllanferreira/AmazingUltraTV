# Credits

## CleanYourTV

AmazingUltraTV is built on [CleanYourTV](https://github.com/Gathin23/cleanyourtv) (formerly tv-vibehack) by Gathin, released under the MIT licence. The launcher's design and code, its translations and tests, and the bundled themes are the work of Gathin and CleanYourTV's contributors. Thank you.

The commit "Import CleanYourTV launcher and themes at 42fe7b0" is an unmodified copy of CleanYourTV's `launcher/`, `themes/` and `.gitattributes`, taken at commit `42fe7b09d61fb9175cb03b8c659cd63c9c1dd9a4`. Everything AmazingUltraTV changed comes in later commits. Later CleanYourTV improvements are pulled in one way only; [UPSTREAM.md](UPSTREAM.md) records the current upstream version and every sync.

## What AmazingUltraTV changed

- **Its own app:** the package id is `com.amazingultratv.home` and the name is AmazingUltraTV, so it installs beside CleanYourTV instead of replacing it. User-visible text in every language names AmazingUltraTV.
- **Security fix:** the `market://launch` handler no longer accepts web links, so a web page can't use it to open apps.
- **Windows scripts:** PowerShell scripts back up the TV, build and install the launcher, push themes and sync upstream. CleanYourTV's Python tools and install scripts are not included.

To see every change to CleanYourTV's files, diff the import commit against the current tree for `launcher/` and `themes/`.

## Third-party material

These keep their own licences, not the repository's MIT licence (see [LICENSE](LICENSE)).

| What | Where | Licence |
| --- | --- | --- |
| Outfit typeface, by The Outfit Project Authors | `launcher/app/src/main/res/font/` | SIL Open Font License 1.1, [launcher/FONT-LICENSE-OFL.txt](launcher/FONT-LICENSE-OFL.txt) |
| Jack-o'-lantern, bat and ghost pictures from Microsoft's Fluent Emoji | `launcher/app/src/main/res/drawable-nodpi/` | MIT, [launcher/ICONS-LICENSE-FLUENT-EMOJI.txt](launcher/ICONS-LICENSE-FLUENT-EMOJI.txt) |
| Cinematic theme wallpaper, by Lukáš Rücker | `themes/cinematic/` | CC0, [themes/cinematic/CREDITS.md](themes/cinematic/CREDITS.md) |
| Halloween theme wallpapers | `themes/halloween/` | CC0, public domain, CC BY and CC BY-SA, [themes/halloween/CREDITS.md](themes/halloween/CREDITS.md) |
| Nature-calm theme photos from Wikimedia Commons | `themes/nature-calm/` | CC BY and CC BY-SA, [themes/nature-calm/CREDITS.md](themes/nature-calm/CREDITS.md) |
| Retro theme wallpapers, by REGT-URRED | `themes/retro/` | CC0, [themes/retro/CREDITS.md](themes/retro/CREDITS.md) |
| Sweden theme photos from Wikimedia Commons | `themes/sweden/` | CC BY and CC BY-SA, [themes/sweden/CREDITS.md](themes/sweden/CREDITS.md) |

The other themes (`aurora`, `default`, `dussehra`, `glass`, `ruska`, `scenes`, `six-columns`) come from CleanYourTV under its MIT licence. The `ruska` and `scenes` wallpapers are drawn from code.
