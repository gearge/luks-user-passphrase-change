# Making the Installers (RPM and DEB packages)

## Preparing the Build Environment on the Development Workstation

### Installing build dependencies on Ubuntu/Debian

Run this [convenience script](install-build-deps-chromium-debian.sh) from Chromium developers. Run it as a sudoer user (not as root).

TODO: this installs lots of irrelevant stuff as well, so extract and provide the important bits only.

### Installing build dependencies on CentOS/Fedora

TODO

Execute commands below as a regular (preferably dedicated) user, not root. No sudo required!

### Configuring rpmbuild

```bash
cat << EOF > ~/.rpmmacros
%_topdir %(echo $HOME)/development/build/rpmbuild
EOF

mkdir -p ~/development/build/rpmbuild
```

### Installing j2cli from PyPI

```bash
pip install j2cli
pip install j2cli[yaml]
```

This should provide the **~/.local/bin/j2** command.

## Building the Packages

```bash
cd ~/development/gearge-luks-user-passphrase-change/installer
VERBOSE=true ./BUILD.sh
```

You will find the packages in:

*   ~/development/build/rpmbuild/RPMS/noarch/
*   ~/development/build/debbuild/DEBS/all/

## Tips

### Install using gdebi on target Ubuntu/Debian systems

Install gdebi to make installing \*.deb packages easier.

```bash
sudo apt update && sudo apt install gdebi
sudo gdebi ./gearge-luks-user-passphrase-change-0.4-23.all.deb
```

### Install using yum on target Ubuntu/Debian systems

```bash
sudo yum install ./gearge-luks-user-passphrase-change-0.4-23.noarch.rpm
```
