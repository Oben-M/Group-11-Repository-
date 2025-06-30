#!/bin/bash

# Clean and build the app
# flutter clean
flutter build apk --debug

# Install and run the app
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.example.network_speed_checker/com.example.network_speed_checker.MainActivity
