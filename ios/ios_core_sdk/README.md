# ThingSmartCryption (Tuya iOS security SDK)

**ThingSmartCryption** is not distributed via CocoaPods. You must download it from the Tuya Developer Platform and place it here so that `ThingSmartHomeKit` (and thus `tuya_home_sdk_flutter`) can resolve.

## Steps

1. Go to [Tuya IoT Platform → Get SDK](https://platform.tuya.com/oem/sdkList).
2. Select your project and download the **App SDK** for **iOS**.
3. Extract the package. You should get an archive (e.g. `ios_core_sdk.tar.gz`) and/or a **Build** folder containing **ThingSmartCryption.xcframework**.
4. In this directory (`ios/ios_core_sdk/`), ensure the following structure exists:
   - `Build/ThingSmartCryption.xcframework/`  
     (with slices such as `ios-arm64`, `ios-x86_64-simulator`, etc.)

So after setup, this folder should contain:

- `ThingSmartCryption.podspec` (already present)
- `Build/ThingSmartCryption.xcframework/` (you add this from the Tuya download)

Then run from the project root:

```bash
cd ios && pod install
```

Your App Key, App Secret, and security image from the same Tuya project must match the values used in the app (e.g. dart-define or config).
