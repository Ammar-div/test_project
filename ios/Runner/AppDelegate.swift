import UIKit
import Flutter
import GoogleMaps

// add this ..
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // add this...
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in 
     GeneratedPluginRegistrant.register(with: registry) }



    GMSServices.provideAPIKey("AIzaSyDlu777DsFcr2_2yVZUoieiaYS94UxT_Do")
    GeneratedPluginRegistrant.register(with: self)

    // add this ...
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
