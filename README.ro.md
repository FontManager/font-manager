
# Font Manager <img src="help/C/media/com.github.FontManager.FontManager-48.png" align="right">
Un manager de fonturi simplu pentru Mediile Desktop GTK.

![Main Window](https://raw.githubusercontent.com/FontManager/font-manager/master/help/C/media/main-window.png)

Font Manager este proiectat pentru a furniza utilizatorilor normali o cale uşoară de a administra fonturile de desktop, făra a fi nevoie de a recurge la command line sau la editarea manuală a fişierelor de configurare. Deşi este proiectat în special pentru Gnome Desktop Environment, ar trebui să meargă bine şi cu alte medii desktop GTK.

Font Manager NU este o soluţie de gestionare a fonturilor de calitate profesională.

## Funcţii
- Pevizualizaţi şi comparaţi fonturi
- Activaţi sau dezactivaţi familii de fonturi
- Categorizare automată bazată pe proprietăţile fontului
- Integrare cu Google Fonts Catalog
- Hartă de caractere integrată
- Colecţii de fonturi ale utilizatorului
- Instalarea şi ştergerea fonturilor utilizatorului
- Setări ale directorului de fonturi ale utilizatorului
- Setări de substituire ale fonturilor utilizatorului
- Setări ale fontului desktopului (GNOME Desktop sau medii compatibile)

## Localizare

Font Manager este tradus folosind [Weblate](https://weblate.org), un instrument web proiectat pentru a uşura traducerea atât pentru dezvoltatori cât şi pentru traducători.

Dacă aţi dori să ajutaţi această aplicaţie să ajungă la mai mulţi utilizatori în limba lor nativă, vă rugăm să accesaţi [pagina proiectului pe Weblate](https://hosted.weblate.org/engage/font-manager/).

<a href="https://hosted.weblate.org/engage/font-manager/">
<img src="https://hosted.weblate.org/widgets/font-manager/-/svg-badge.svg" alt="Translation status" />
</a>

## Instalare


### Flatpak

<a href='https://flathub.org/apps/details/org.gnome.FontManager'><img width='220' alt='Download on Flathub' src='https://flathub.org/assets/badges/flathub-badge-i-en.png'/></a>

- Accesul la xdg-config/fontconfig este necesar pentru ca alte aplicaţii Flatpak să recunoască schimbările făcute  Font Manager. Puteţi folosi o aplicaţie ca [Flatseal](https://flathub.org/apps/details/com.github.tchx84.Flatseal) sau să adăugaţi --filesystem=xdg-config/fontconfig la comanda utilizată pentru a deschide aplicaţia. Acest lucru trebuie făcut pentru fiecare program Flatpak instalat.

- Suportul pentru arhive nu funcţionează în aplicaţia Flatpak.

### Pachetele distribuţiilor

#### Arch User Repository

Utilizatorii Arch Linux pot instala [`font-manager`](https://archlinux.org/packages/community/x86_64/font-manager/) din depozitele oficiale:

```bash
pacman -S font-manager
```

#### Fedora COPR

[![Copr build status](https://copr.fedorainfracloud.org/coprs/jerrycasiano/FontManager/package/font-manager/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/jerrycasiano/FontManager/package/font-manager/)

Pachete Fedora construite din ultima revizie:
```bash
dnf copr enable jerrycasiano/FontManager
dnf install font-manager
```

#### Gentoo

Utilizatorii Gentoo pot găsi [`font-manager`](https://github.com/PF4Public/gentoo-overlay/tree/master/app-misc/font-manager) în [::pf4public](https://github.com/PF4Public/gentoo-overlay) Gentoo overlay

#### Ubuntu Personal Package Archive
Pakete Ubuntu cunstruite din ultima revizie:
```bash
sudo add-apt-repository ppa:font-manager/staging
sudo apt-get update
sudo apt-get install font-manager
```

#### Extensii pentru Managerele de Fişiere

Utilizatorii Ubuntu şi Fedora pot găsi extensii pentru Nautilus, Nemo and Thunar în the repository-uri.

Extensia, în acest moment, vă permite să previzualizaţi fonturi doar selectându-le în managerul de fişiere în timp ce font-viewer este deschis şi adaugă o opţiune pentru a instala fonturi în meniul contextual al managerul de fişiere.

Extensia Thunar are, de asemenea, suport de bază pentru redenumire bulk.

### Construirea din sursă

Va trebui să vă asiguraţi că următoarele depentenţe sunt instalate:

- `meson >= 0.59`
- `ninja`
- `glib >= 2.62`
- `vala >= 0.56`
- `freetype2 >= 2.10`
- `gtk+-4.0 >= 4.12`
- `json-glib-1.0 >= 1.5`
- `libxml-2.0 >= 2.9.10`
- `sqlite3 >= 3.35`
- `gobject-introspection`
- `yelp-tools` (opţional)
- `gettext` (opţional)

Dacă doriţi să construiţi şi extensiile pentru managerul de fişiere, veţi avea nevoie de bibliotecile de dezvoltare corespunzătoare:

- `libnautilus-extension`
- `libnemo-extension`
- `thunar`

Dacă doriţi să construiţi şi integrare cu Google Fonts, care este activată implicit, următoarele biblioteci sunt necesare:

- `webkitgtk-6.0 >= 2.4`
- `libsoup3 >= 3.2`

Pentru a construi aplicaţia:

```bash
meson --prefix=/usr --buildtype=release build
cd build
ninja
```

Penru a rula aplicaţia fără a o instala:

```bash
src/font-manager/font-manager
```

Pentru a instala aplicaţia:

```bash
sudo ninja install
```

Pentru dezinstalare:

```bash
sudo ninja uninstall
```

Pentru o listă cu opţiunile de construire disponibile:

```bash
meson configure
```

Penru a schimba o opţiune după ce directorul de construcţie a fost configurat:

```bash
meson configure -Dsome_option=true
```

## Licenţă

Acest proiect este licenţiat sub GNU General Public License Version 3.0 - vedeţi
[COPYING](COPYING) pentru detalii.

## Mulţumiri

- Lui Karl Pickett pentru punere lucrurilor în mişcare cu [fontmanager.py](https://raw.githubusercontent.com/FontManager/font-manager/6b9b351538b5118d07f6d228f3b42c91183b8b73/fontmanager.py)
- Modul de comparare în Font Manager este modelat după [gnome-specimen](https://launchpad.net/gnome-specimen) de Wouter Bolsterlee
- Font Manager foloseşte date compilate pentru [Fontaine](http://www.unifont.org/fontaine/) de Edward H. Trager
- Harta de caractere din Font Manager este bazată pe [Gucharmap](https://wiki.gnome.org/action/show/Apps/Gucharmap)
