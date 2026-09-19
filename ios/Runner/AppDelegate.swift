import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets scheduled reminders show while the app is open and reach the
    // plugin when tapped.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The home screen widgets (lib/services/home_widgets.dart): the snapshot
    // goes to the App Group the widget extension reads, then every widget
    // reloads; the days marked on them come back. Keys match
    // KacGunOlduWidget/WidgetSnapshot.swift.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KacGunOlduWidgets") {
      FlutterMethodChannel(name: "kac_gun_oldu/widgets", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          let group = UserDefaults(suiteName: "group.com.emalabs.kacgunoldu")
          switch call.method {
          case "publish":
            if let snapshot = call.arguments as? String {
              group?.set(snapshot, forKey: "widgets.snapshot")
            }
            if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
            }
            result(nil)
          case "takeMarks":
            // Days marked with a widget's "Bugün yaptım", for CardStore.
            result(group?.string(forKey: "widgets.marks") ?? "[]")
            group?.removeObject(forKey: "widgets.marks")
          case "canPin":
            // iOS has no way to place a widget from the app.
            result(false)
          default:
            result(FlutterMethodNotImplemented)
          }
        }
    }
  }
}
