#install yay from pkgbuild file to the system and not from the aur
#download the pkgbuild file from the aur
curl -O https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay
#install yay from the pkgbuild file
gum spin --spinner dot --title "Installing Yay" -- makepkg -si

#check if yay is installed
if [ -f /usr/bin/yay ]; then
    echo "Yay is installed"
    exit 0
