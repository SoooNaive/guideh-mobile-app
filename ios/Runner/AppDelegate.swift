import UIKit
import Flutter
import YandexMapsMobile
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // yandex maps
    YMKMapKit.setLocale("ru_RU")
    YMKMapKit.setApiKey("c4b8806f-7cb8-493a-903b-e4e01db711c9")

    GeneratedPluginRegistrant.register(with: self)

    // flutter_local_notifications
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // shows notifications even if app is in foreground
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    } else {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // workmanager (or flutter_local_notifications?): shows notifications even if app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler(.alert)
  }


}
