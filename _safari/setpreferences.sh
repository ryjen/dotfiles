#!/bin/sh

CMD=/usr/libexec/PListBuddy

$CMD -c "Set NewTabBehavior 1" ~/Library/Preferences/com.apple.Safari.plist
$CMD -c "Set NewWindowBehavior 1" ~/Library/Preferences/com.apple.Safari.plist

