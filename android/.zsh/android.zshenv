export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/$(ls -r $ANDROID_HOME/build-tools | head -n 1):$ANDROID_HOME/emulator
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
