# box_master
This repository contains the Flutter application for the Box Master project, which connects to the Custom Locker Extended hardware via Bluetooth to sync health data using Google Health Connect.

## Features
- detect if bluetooth is enabled and request permissions for health connect
- Syncs health data using Google Health Connect
- Connects to [Custom Locker Extended](https://github.com/itsLeatch/customLockerExtended) via Bluetooth

<img src="https://github.com/user-attachments/assets/c3188fc4-8a68-4362-b6d0-0e3f40f921c1" width="256">

# How to build
1. Clone the repository
2. Ensure you have Flutter installed and set up on your machine
3. Run `flutter pub get` to install dependencies
4. Run 'flutter build apk --release' to build the release APK for Android devices
5. Install the APK on your Android device and connect to the Custom Locker Extended hardware via Bluetooth