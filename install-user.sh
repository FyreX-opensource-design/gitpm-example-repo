wget -P ~/.local/share/apps/nativefier/ https://github.com/macdems/nativefier/releases/download/v57.0.0/nativefier-57.0.0.tgz
CURRENT_DIR=$(pwd)
cd ~/.local/share/apps/nativefier/
npm install ~/.local/share/apps/nativefier/nativefier-57.0.0.tgz
cd $CURRENT_DIR
