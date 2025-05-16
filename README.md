# VPN App

A cross-platform VPN application built with Flutter for Windows, macOS, Android, and iOS. The app allows users to connect to a VPN server, purchase individual or family subscriptions, and use the service across multiple devices.

## Status
The project is in active development (alpha stage). Current features include basic UI for login and home screens. Upcoming features:
 - VPN connection via WireGuard/OpenVPN.
 - Subscription management with in-app purchases.
 - Multi-device synchronization.

## Features
- Secure VPN connection using protocols like WireGuard or OpenVPN.
- Individual and family subscription plans.
- Cross-platform support: Windows, macOS, Android, iOS.
- User authentication and multi-device synchronization.
- User-friendly interface for selecting VPN servers and managing subscriptions.

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel, version 3.x.x or later).
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter).
- [Android Studio](https://developer.android.com/studio) for Android development.
- [Xcode](https://developer.apple.com/xcode/) for iOS/macOS development (requires macOS).
- [Visual Studio](https://visualstudio.microsoft.com/) with Desktop development with C++ for Windows development.
- [Git](https://git-scm.com/) for version control.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/shamovgk/vpn_app.git
   cd vpn_app
2. Install dependencies:
    ```bash
    flutter pub get
3. Enable platform support (if needed):
    ```bash
    flutter config --enable-windows-desktop
    flutter config --enable-macos-desktop
    flutter config --enable-linux-desktop

### Running the App
1. Connect a device or start an emulator/simulator:
 -  Android: Use Android Studio to start an emulator.
 -  iOS: Use Xcode to start a simulator (macOS only).
 -  Windows/macOS: Ensure Developer Mode is enabled (Windows) or Xcode is set up (macOS).
2. Run the app:
    ```bash
    flutter run
 - Or specify a platform:
    ```bash
    flutter run -d windows
    flutter run -d android
    flutter run -d ios

### Building the App
 - To build a release version:
    ```bash
    flutter build apk  # Android
    flutter build ios  # iOS (requires macOS)
    flutter build windows  # Windows
    flutter build macos  # macOS

## Project Structure
vpn_app/  
├── android/              # Android-specific files  
├── ios/                  # iOS-specific files  
├── windows/              # Windows-specific files  
├── macos/                # macOS-specific files  
├── lib/                  # Flutter source code  
│   ├── screens/          # UI screens (e.g., login,   home, subscription)  
│   ├── providers/        # State management (e.g.,   VpnProvider)  
│   ├── main.dart         # Entry point  
├── test/                 # Unit and widget tests  
├── pubspec.yaml          # Dependencies and project   configuration  
├── .gitignore            # Files ignored by Git  
├── .gitattributes        # Line ending rules  
├── README.md             # Project documentation  
├── CONTRIBUTING.md       # Contribution guidelines  
├── LICENSE               # License file  

## Contributing
Contributions are welcome!  
Please read CONTRIBUTING.md for details on how to contribute, including branch naming conventions and the pull request process.

## Branch Naming
 - Use feature/<feature-name> for new features (e.g., feature/subscription-screen).
 - Use bugfix/<bug-description> for bug fixes (e.g., bugfix/login-error).
 - Use docs/<doc-update> for documentation updates (e.g., docs/update-readme).
 - Use hotfix/<issue-description> for urgent fixes (e.g., hotfix/vpn-connection).

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
For questions or feedback, open an issue on GitHub or contact [shamov.gkurban@gmail.com].
