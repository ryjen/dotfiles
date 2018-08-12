# GNU core utilities
eval `dircolors ~/.zsh/dircolors.256dark`      # colored ls

if type xmodmap > /dev/null; then
    xmodmap ~/.Xmodmap
fi

if type xdg-open > /dev/null; then
    alias open='xdg-open'
fi 

xinput set-prop "c0der78’s Mouse" 286 1 &> /dev/null

