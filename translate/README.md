# Translations

> [!WARNING]
> Translations are currently not being loaded by wallpaper plugins when installing from the KDE Store see [issue #84](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/issues/84)
>
> For now they only work when installing system-wide using `./install.sh` or from a Distribution package

## Prerequisites

Make sure you have the package `gettext` installed on your system, as it is required for managing translations.

Optionally, a graphical editor for translation files (e.g [Lokalize](https://apps.kde.org/es/lokalize/)) is if you aren't familiar with the format.

## I18n helper script

The project comes with a helper script (`bin/i18n`) to manage translations:

1. **Extract translatable strings** from the source code:

   ```sh
   ./bin/i18n extract
   ```

   Creates/updates the translation template file (`translate/template.pot`) and updates existing `.po` files.

1. **Check translation status**:

   ```sh
   ./bin/i18n check
   ```

   Check if translations template is up to date and shows how many strings are untranslated in each language file.

1. **Initialize a new language**:

   ```sh
   ./bin/i18n init <lang_code>
   ```

   For example, `./bin/i18n init fr` creates a new French translation file.

   Your region's locale code can be found at: <https://stackoverflow.com/questions/3191664/list-of-all-locales-and-their-short-codes/28357857#28357857>

1. **Compile translations**:

   ```sh
   ./bin/i18n compile
   ```

   This compiles all `.po` files into `.mo` files that the plugin can use.

## Contributing Translations

1. Create or edit a `.po` file in the `translate/` directory.
1. Compile the translations to verify they work correctly.
1. Submit a pull request with your changes to the `translate/` directory, do not include the compiled `.mo` files, as they will be generated automatically during the build process.

## Acknowledgements

- This project a rewrite based on [adhec/Smart Video Wallpaper](https://github.com/adhec/plasma_tweaks/tree/master/SmartVideoWallpaper) and [PeterTucker/smartER-video-wallpaper](https://github.com/PeterTucker/smartER-video-wallpaper) projects.
- [ccatterina's script](https://github.com/ccatterina) to manage translations
- Brand icons from [Simple Icons](https://simpleicons.org)
