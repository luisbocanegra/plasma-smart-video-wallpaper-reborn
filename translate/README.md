# Translations

> [!IMPORTANT]
> If the plugin is installed from KDE Store/kpackagetool6 (non system-wide), translations will only be loaded from Plasma 6.5.6 and later ([upstream bug fixed](https://bugs.kde.org/show_bug.cgi?id=501400)).
>
> For System-wide installs via `./install.sh` or distribution package translations should work with older Plasma too for 2.10.0 or later versions of this wallpaper plugin.

## Prerequisites

Make sure you have the package `gettext` installed on your system, as it is required for managing translations.

Optionally, a graphical editor for translation files (e.g [Lokalize](https://apps.kde.org/es/lokalize/)) is if you aren't familiar with the format.

## I18n helper script

The project comes with a helper script (`bin/i18n`) to manage translations:

1. **Check translation status**:

   ```sh
   ./bin/i18n check
   ```

   Check if translations template is up to date and shows how many strings are untranslated in each language file.

2. **Initialize a new language**:

   ```sh
   ./bin/i18n init <lang_code>
   ```

   For example, `./bin/i18n init fr` creates a new French translation file.

   Your region's locale code can be found at: <https://stackoverflow.com/questions/3191664/list-of-all-locales-and-their-short-codes/28357857#28357857>

3. **Compile translations**:

   ```sh
   ./bin/i18n compile
   ```

   This compiles all `.po` files into `.mo` files that the plugin can use.

## Contributing Translations

1. Create or edit a `.po` file in the `translate/` directory.
1. Compile the translations to verify they work correctly.
1. Submit a pull request with your changes to the `translate/` directory, do not include the compiled `.mo` files, as they will be generated automatically during the build process.
