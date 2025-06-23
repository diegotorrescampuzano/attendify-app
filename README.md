# Attendify Project

**Author:** Diego Torres  
**Email:** diegotores50@gmail.com

---

## Project Overview

Attendify is a mobile application developed in Flutter to manage teacher schedules and attendance across multiple campuses. The app allows tracking of class assignments, teacher availability, and homeroom information for each subject and time slot.

---

## Project Structure

- **Main application:** Flutter codebase for Android and iOS support.
- **Firebase integration:** Used for authentication, data storage, and backend services.
- **Schedule management:** Supports importing and exporting teacher schedules in CSV format.
- **Cross-platform:** Single codebase for both Android and iOS devices.

---

## Getting Started

### 1. Clone the Repository

git clone https://github.com/diegotorrescampuzano/attendify-app.git
cd attendify-app


### 2. Install Dependencies

Attendify uses [FVM (Flutter Version Management)](https://fvm.app) to ensure consistent Flutter SDK usage.

**Install FVM if not already installed:**

dart pub global activate fvm


**Install required Flutter version:**

fvm install 3.32.0
fvm use 3.32.0


> **Note:** On Windows, you may need to run `fvm use 3.32.0` in an administrator terminal if you encounter permission errors.

### 3. Install Project Dependencies

fvm flutter pub get


### 4. Run the App

fvm flutter run


This will launch the app on a connected device or emulator.

---

## Android Studio IDE Configuration

1. **Set Flutter SDK path in Android Studio:**
    - Go to **File > Settings > Languages & Frameworks > Flutter**
    - Set the SDK path to:
      ```
      <project-dir>/.fvm/flutter_sdk
      ```
    - Replace `<project-dir>` with your actual project directory (e.g., `C:\Development\Attendify Project\attendify-app`).

2. **Import IDE Settings:**
    - Download or copy the `settings.zip` file from the project.
    - In Android Studio, go to **File > Manage IDE Settings > Import Settings**.
    - Select the `settings.zip` file to import your preferred IDE configurations.

---

## Firebase Configuration

1. **Add your `firebase.json` file to the project root.**
2. **Configure Firebase in your Flutter project:**
    - Follow the official [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview/) for your platform.
    - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files to the respective directories.

### Firebase Commands

- **Login to Firebase:**
  fvm flutter pub global activate firebase_tools
  firebase login

- **Deploy Firebase functions or rules:**
  firebase deploy

- **Logout from Firebase:**
  firebase logout


---

## Schedule Data

Attendify uses CSV files to manage teacher schedules. Example files include:
- **Docente-Lunes-Martes-Mircoles-Jueves-Viernes-Sbado-Domingo.csv**
- **Campus-TeacherName-Date-Day-Time-SlotNumber-Subject-Homeroom.csv**

These files are parsed and displayed within the app to show teacher availability and class assignments[1][2].

---

## Testing on Android Device

1. **Enable Developer Mode:**
- Go to **Settings > About phone**.
- Tap **Build number** 7 times to enable Developer options.
2. **Enable USB Debugging:**
- Go to **Settings > System > Developer options**.
- Enable **USB debugging**.
3. **Connect your device:**
- Connect your Android phone to your computer via USB.
- Run:
  ```
  fvm flutter devices
  ```
- Select your device and run:
  ```
  fvm flutter run
  ```

---

## Generating APK

To build a release APK:

fvm flutter build apk


The APK will be generated in:
build/app/outputs/flutter-apk/app-release.apk


---

## Summary of Commands

| Command                                  | Description                                    |
|-------------------------------------------|------------------------------------------------|
| `fvm install 3.32.0`                     | Install Flutter 3.32.0                         |
| `fvm use 3.32.0`                         | Use Flutter 3.32.0 in this project             |
| `fvm flutter clean`                      | Clean the project build                        |
| `fvm flutter pub get`                    | Get project dependencies                       |
| `fvm flutter run`                        | Run the app on a device/emulator               |
| `fvm flutter build apk`                  | Build a release APK                            |
| `firebase login`                         | Log in to Firebase CLI                         |
| `firebase deploy`                        | Deploy Firebase resources                      |
| `firebase logout`                        | Log out from Firebase CLI                      |

---

## License

This project is open-source. For more details, see the [LICENSE](LICENSE) file.

---

**Author:** Diego Torres  
**Contact:** diegotores50@gmail.com