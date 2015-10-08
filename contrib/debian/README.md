
Debian
====================
This directory contains files used to package bitcoind/beardcoin-qt
for Debian-based Linux systems. If you compile bitcoind/beardcoin-qt yourself, there are some useful files here.

## beardcoin: URI support ##


beardcoin-qt.desktop  (Gnome / Open Desktop)
To install:

	sudo desktop-file-install beardcoin-qt.desktop
	sudo update-desktop-database

If you build yourself, you will either need to modify the paths in
the .desktop file or copy or symlink your beardcoin-qt binary to `/usr/bin`
and the `../../share/pixmaps/bitcoin128.png` to `/usr/share/pixmaps`

beardcoin-qt.protocol (KDE)

