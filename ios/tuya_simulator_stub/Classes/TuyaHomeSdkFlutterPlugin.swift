import Flutter
import UIKit

/// Lightweight stub used on arm64 iOS simulators where Tuya prebuilt XCFrameworks
/// (ThingSmartUtil) do not ship an arm64-simulator slice.
@available(iOS 13.0, *)
public class TuyaHomeSdkFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let deviceDiscoveryHandler = DeviceDiscoveryStreamHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "tuya_home_sdk_flutter",
      binaryMessenger: registrar.messenger()
    )
    let event = FlutterEventChannel(
      name: "tuya_home_sdk_flutter_device_dps_event",
      binaryMessenger: registrar.messenger()
    )
    let deviceEvent = FlutterEventChannel(
      name: "tuya_home_sdk_flutter_device_discovery_event",
      binaryMessenger: registrar.messenger()
    )

    let instance = TuyaHomeSdkFlutterPlugin()
    event.setStreamHandler(instance)
    deviceEvent.setStreamHandler(instance.deviceDiscoveryHandler)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initSDK":
      result(false)
    case "getHomeList", "getHomeRooms", "getHomeDevices", "discoverDevices",
         "queryMemberList", "queryInvitations", "getSceneList":
      result([])
    case "getWifiSsid":
      result("")
    case "getUserInfo":
      result([String: Any]())
    default:
      result(
        FlutterError(
          code: "TUYA_SIMULATOR",
          message: "Tuya native SDK is disabled on the iOS simulator. Use a physical device for smart-device features.",
          details: call.method
        )
      )
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    nil
  }
}

@available(iOS 13.0, *)
private final class DeviceDiscoveryStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    nil
  }
}
