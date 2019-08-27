# ![Logo](gearge-luks-user-passphrase-change/product_logo_96.png) Giorgi's LUKS User Passphrase Changer

Bespoke graphical application to allow changing or recovering user's full disk encryption (LUKS) passphrase. Written in Bash with GTK+ dialogs provided via zenity CLI. Primarily for use on GNU/Linux based laptops. Installer creates native RPM and DEB packages for Red Hat and Debian OS family systems respectively.

The user will be prompted to change the default LUKS passphrase (provided by IT) on first GNOME login. If this change is successful, the user will not be prompted again. The user can also change the passphrase on demand at any time.

## Source Code Directory Structure

Document for making the installer in [installer/README.md](installer/README.md).
