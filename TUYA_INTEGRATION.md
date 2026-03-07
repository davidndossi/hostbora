# Tuya IoT Integration

This app can integrate with **Tuya-compatible devices** (smart locks, IP cameras, sensors, etc.) using the [Tuya Smart Life App SDK](https://developer.tuya.com/en/docs/app-development/smart-ipc-sdk?id=Kdjvlq8i9jhi2) via the Flutter plugin [tuya_home_sdk_flutter](https://pub.dev/packages/tuya_home_sdk_flutter).

## 1. Tuya Developer Setup

1. **Create an account** at [Tuya IoT Platform](https://iot.tuya.com/).
2. **Create a project** (Cloud → Development → Create Project).
3. **Link your app** (Android / iOS) and get:
   - **App Key** (Client ID)
   - **App Secret** (Client Secret)
4. **Download the security SDK** for your app (required by Tuya):
   - Go to [Get SDK](https://platform.tuya.com/oem/sdkList) and download the **App SDK** for Android and/or iOS.
   - Extract the package:
     - **Android:** Place `security-algorithm.aar` in `android/app/libs/` (create the folder if needed).
     - **iOS:** Extract `ios_core_sdk.tar.gz` and copy the `ios_core_sdk` directory into your project’s `ios/` folder. You will need the **Tuya Key** (security key) from this package for initialization.

## 2. Flutter / Dart Config

Credentials are read from **dart-define** (or you can pass them in code). Do not commit real keys.

**iOS and Android use different App Key / App Secret** on the Tuya platform. The app supports both:

- **Platform-specific (recommended when keys differ):**  
  Android: `TUYA_APP_KEY_ANDROID`, `TUYA_APP_SECRET_ANDROID`, `TUYA_SECURITY_KEY_ANDROID`  
  iOS: `TUYA_APP_KEY_IOS`, `TUYA_APP_SECRET_IOS`, `TUYA_SECURITY_KEY_IOS`
- **Fallback (same key for both):** `TUYA_APP_KEY`, `TUYA_APP_SECRET`, `TUYA_SECURITY_KEY`

**Option A – dart-define (recommended):**

```bash
# When iOS and Android have different keys (pass all; the right set is chosen per platform):
flutter run --dart-define=TUYA_APP_KEY_IOS=ios_key --dart-define=TUYA_APP_SECRET_IOS=ios_secret --dart-define=TUYA_SECURITY_KEY_IOS=ios_security_key \
  --dart-define=TUYA_APP_KEY_ANDROID=android_key --dart-define=TUYA_APP_SECRET_ANDROID=android_secret --dart-define=TUYA_SECURITY_KEY_ANDROID=android_security_key

# Or a single set for both platforms:
flutter run --dart-define=TUYA_APP_KEY=your_app_key --dart-define=TUYA_APP_SECRET=your_app_secret --dart-define=TUYA_SECURITY_KEY=your_security_key
```

**Option B – code:** Edit `lib/main.dart` and create `TuyaConfig` with your values (only for local testing; use env or dart-define for production).

If the chosen set (platform-specific or fallback) is missing any value, the Tuya SDK is **not** initialized and the app runs without Tuya.

## 3. Android Setup

1. **Permissions** in `android/app/src/main/AndroidManifest.xml` (add inside `<manifest>`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

2. **AAR and NDK** in `android/app/build.gradle.kts`:

In `android { defaultConfig { ... } }` add:

```kotlin
ndk {
    abiFilters += listOf("armeabi-v7a", "arm64-v8a")
}
packaging {
    jniLibs {
        pickFirsts += "lib/*/libc++_shared.so"
    }
}
```

In `dependencies { }` add:

```kotlin
implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
```

3. **ProGuard** (if you use minify): in `android/app/proguard-rules.pro` add the rules from the [Tuya Flutter plugin readme](https://pub.dev/packages/tuya_home_sdk_flutter) (Flutter, FastJson, MQTT, OkHttp3, Thingclips, etc.).

4. **Tuya native SDK (optional):** For full features (e.g. Smart Camera IPC SDK), add the Tuya Android BizBundles as described in [Tuya Android docs](https://developer.tuya.com/en/docs/app-development/featureoverview?id=Ka69nt97vtsfu) and in the plugin’s Android section.

## 4. iOS Setup

1. **Info.plist** – add usage descriptions (Bluetooth, Location, Camera, etc.) as in the [Tuya Flutter plugin readme](https://pub.dev/packages/tuya_home_sdk_flutter).

2. **Podfile** – add Tuya specs and the security pod:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/TuyaInc/TuyaPublicSpecs.git'
source 'https://github.com/tuya/tuya-pod-specs.git'

platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  pod "ThingSmartCryption", :path => './ios_core_sdk'
end
```

3. Run `pod install` in the `ios/` directory after placing `ios_core_sdk` and the Podfile changes.

## 5. Using the Tuya Service in the App

- **Initialization:** If `TuyaConfig.fromEnvironment()` has valid `appKey`, `appSecret`, and `securityKey`, the app initializes `TuyaService` in `main()` and registers it with GetX.

- **Access in code:**

```dart
if (Get.isRegistered<TuyaService>()) {
  final tuya = Get.find<TuyaService>();
  if (tuya.isInitialized) {
    final homes = await tuya.getHomeList();
    for (final home in homes) {
      final devices = await tuya.getHomeDevices(home.homeId);
      // Use devices (locks, cameras, etc.)
    }
  }
}
```

- **Device control:** Use `tuya.publishDps(deviceId: id, dps: {'1': true})` with the DPS map for your product (e.g. lock state, power).
- **Real-time updates:** Use `tuya.onDeviceDpsUpdated(deviceId: id)` to listen to state changes.
- **Pairing:** Use `tuya.discoverDevices()` and the SDK’s WiFi/BLE config methods (see plugin docs).

## 6. Smart Lock SDK – Remote Lock / Unlock

The app integrates with the [Tuya Smart Lock SDK](https://developer.tuya.com/en/docs/app-development/smart-lock-sdk?id=Kdjvl28puletn) so you can **lock and unlock compatible devices remotely**.

### How it works

- **TuyaSmartLockService** (in `lib/app/data/service/tuya_smart_lock_service.dart`) wraps `TuyaService` and adds:
  - **lock(deviceId)** / **unlock(deviceId)** – send remote lock/unlock via device DPS (data points).
  - **onLockStateUpdated(deviceId)** – stream of state changes (e.g. when someone unlocks locally).
  - **getLockDevices()** – list of Tuya devices that look like locks (name/productId contains "lock" or "door_lock").
- Lock commands use the common Tuya lock DP **`1`** with values **`lock`** / **`unlock`**. If your lock product uses different DPS, adjust `defaultLockStateDpId` and values in `TuyaSmartLockService` or use the product's [DP documentation](https://developer.tuya.com/en/docs/iot/lock?id=K9wjnt8v958nh).
- **Smart Access** screen:
  - On load, if Tuya is initialized, the controller fetches lock devices and uses the first one.
  - **Unlock Door** / **Lock Door** call TuyaSmartLockService when a lock device is available; otherwise they only update local UI.
  - Lock state is kept in sync by subscribing to `onLockStateUpdated`.

### Tuya user and device list

Remote lock/unlock works only after:

1. **Tuya user login** – call `TuyaService.loginWithUserName(...)` (or OAuth) after your app user logs in. Link your user to the same Tuya account that owns the lock.
2. **Lock on same account** – the lock must be added in the Tuya app (or via your app's pairing flow) under that account.

If you have multiple locks, extend the UI to let the user pick a device (e.g. from `getLockDevices()`) and pass that `deviceId` to lock/unlock.

## 7. Smart Access / Guest Access

The **Smart Access** and **Guest Access Codes** screens are the right place to:

- List Tuya smart locks and their status.
- Unlock/lock remotely via **TuyaSmartLockService** (see section 6).
- Show activity from `onDeviceDpsUpdated` or from your backend if you sync Tuya events there.

Product-specific DPS codes (e.g. which key is “lock state”) are in the [Tuya Smart Lock](https://developer.tuya.com/en/docs/iot/lock?id=K9wjnt8v958nh) and product DP documentation.

## 8. References

- [Smart Camera SDK (IPC) – Tuya](https://developer.tuya.com/en/docs/app-development/smart-ipc-sdk?id=Kdjvlq8i9jhi2)
- [Smart Lock SDK – Tuya](https://developer.tuya.com/en/docs/app-development/smart-lock-sdk?id=Kdjvl28puletn)
- [Smart Lock product & DP reference](https://developer.tuya.com/en/docs/iot/lock?id=K9wjnt8v958nh)
- [Tuya Home SDK Flutter – pub.dev](https://pub.dev/packages/tuya_home_sdk_flutter)
- [Tuya IoT Platform](https://iot.tuya.com/)
- [Get SDK (downloads)](https://platform.tuya.com/oem/sdkList)
