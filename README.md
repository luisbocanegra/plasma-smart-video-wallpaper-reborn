## Welcome to my look and feel themes for Plasma

<iframe width="753" height="380" src="https://www.youtube.com/embed/Fv4ryIh0_1M" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen autoplay="1"></iframe>

---

### Light and dark themes

[![screen](https://raw.githubusercontent.com/adhec/plasma_tweaks/master/images/pear_light_02b.png)](https://raw.githubusercontent.com/adhec/plasma_tweaks/master/images/pear_light_02.png)

[![screen](https://raw.githubusercontent.com/adhec/plasma_tweaks/master/images/pear_dark_01b.png)](https://raw.githubusercontent.com/adhec/plasma_tweaks/master/images/pear_dark_01.png)

---

### 1 Installation

Install from Plasma SystemSettings:

```bash
[ SystemSettings > Look and Feel > Get New Look and Feel > Search "Pear" > Click in install button ]
```

### 2 Usage

Select the theme from the SystemSettings > Look and Feel

### 3 Services menu for change animations

#### Dependencies

Most cases are already installed by default, but to confirm install:

Arch
- sudo pacman -S imagemagick
- sudo pacman -S kdialog

Ubuntu
- sudo apt install imagemagick
- sudo apt install kdialog

#### 3.1 Change animation of the session

[![screen](https://raw.githubusercontent.com/adhec/plasma_tweaks/master/images/menu_session.png)]()

```bash
1. Right click on your preferred animation to open the menu
2. Select "Actions"
3. Choose "Set as Session GIF"
```
The chosen animation is independent of the animation used by the SDDM login manager.

### 3.2 Change animation of the splashscreen

[![screen](https://raw.githubusercontent.com/adhec/plasma_tweaks/master/images/menu_splash.png)]()

```bash
1. Right click on your preferred animation to open the menu
2. Select "Actions"
3. Choose "Set as Splashscreen GIF"
```

For test the splash screen, from terminal write:
```bash
# replace "PearLight" with your current theme
ksplashqml --test --window ~/.local/share/plasma/look-and-feel/PearLight
```

## For animations in Login manager Plasma (SDDM) 

Visit [Ittu themes for SDDM](https://adhec.github.io/sddm_themes/)

# Coffee

### Coffee

Thanks for all the support. If you like what I do,
Share your ❤️ Buy me a ☕

[<img src="https://www.paypalobjects.com/webstatic/en_US/i/buttons/PP_logo_h_100x26.png"  style="width:72px;">](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=V9Q8MK9CKSQW8&source=url)  or  [<img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg">](https://liberapay.com/_adhe_/donate)

Have fun ;)

