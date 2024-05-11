#!/bin/bash
# usage of this script
# for backup use "./xfce-backup.sh backup"
# for restore from backup use "./xfce-backup.sh restore"
# while using restore, xfce4-backup.tar.gz have to be in the same directory with this script
MODE=$1 # mode
VERSION="0.0.2"

exists() {
  command -v "$1" >/dev/null 2>&1
}

if exists gsettings; then
    :
else
  echo 'Cannot detect gsettings'
  echo "if you're on Debian you can install with libglib2.0-bin package from official repositories"
  exit
fi

if exists xfconf-query; then
    :
else
    echo 'Cannot detect xfconf-query'
    exit
fi

if exists tar; then
    :
else
    echo 'Cannot detect tar'
    exit
fi

if exists gzip; then
    :
else
    echo 'Cannot detect gzip'
fi

if [ "$(id -u)" == 0 ]; then
    echo 'you must use this script as home user'
    exit
else
    :
fi

if [ -z "$1" ]; then
    echo 'Please read how to use.'
    exit
fi

# main backup function
backupmain() {
    #current themes
    eval THEME="$(gsettings get org.gnome.desktop.interface gtk-theme)"
    eval ICON="$(gsettings get org.gnome.desktop.interface icon-theme)"
    eval CURSOR="$(gsettings get org.gnome.desktop.interface cursor-theme)"
    eval CURSORSIZE="$(xfconf-query -c xsettings -p /Gtk/CursorThemeSize)"
    cp -r "/$HOME/.config/xfce4/" .
    mkdir Theme && cp -r "/usr/share/themes/$THEME" ./Theme
    mkdir Icons && cp -r "/usr/share/icons/$ICON" ./Icons
    mkdir Cursor && cp -r "/usr/share/icons/$CURSOR" ./Cursor
    echo "$THEME" >> ./Theme/currenttheme
    echo "$ICON" >> ./Icons/currenticon
    echo "$CURSOR" >> ./Cursor/currentcursor && echo "$CURSORSIZE" >> ./Cursor/currentsize
    echo "$VERSION" >> version
    tar -czf ./xfce4-backup.tar.gz xfce4 Theme Icons Cursor version
    cp ./xfce4-backup.tar.gz "./out/"
    rm -r xfce4 Theme Icons Cursor xfce4-backup.tar.gz version
}

backup() {
    if [ -f "./out/xfce4-backup.tar.gz" ]; then
        backupmain
        echo "backup file successfully overwritten!"
        echo "Please check files inside archive to ensure backup files are correct"
    else
        backupmain
        echo "backup file successfully created!"
        echo "Please check files inside the archive to ensure backup files are correct"
    fi
}

restore() {
    tar -xf ./xfce4-backup.tar.gz
    THEME=$(cat ./Theme/currenttheme)
    ICON=$(cat ./Icons/currenticon)
    CURSOR=$(cat ./Cursor/currentcursor)
    CURSORSIZE=$(cat ./Cursor/currentsize)
    cp -r xfce4 "$HOME/.config/"
    sudo cp -r "./Theme/$THEME" "/usr/share/themes/"
    sudo cp -r "./Icons/$ICON" "/usr/share/icons/"
    sudo cp -r "./Cursor/$CURSOR" "/usr/share/icons/"
    xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON"
    xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "$CURSOR"
    xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s "$CURSORSIZE"
    rm -r xfce4 Theme Icons Cursor
    echo "xfce config and theme restored"
}

# Check for the mode
if [ "$MODE" = backup ]; then
    if [ -d "/$HOME/.config/xfce4/" ]; then
        # create an output file if it isn't exists
        if [ -d "./out/" ]; then
            :
        else
            mkdir out
        fi
        backup
    else
        echo "couldn't find the config"
    fi
elif [ "$MODE" = restore ]; then
    if [ -f "./xfce4-backup.tar.gz" ]; then
        restore
    else
        echo "couldn't find the config"
    fi
else
    echo "error '$MODE' is not an argument use 'backup' or 'restore'"
fi
