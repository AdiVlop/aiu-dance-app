import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // No FirebaseApp.configure() here.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
