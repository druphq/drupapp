import Flutter
import UIKit
import GoogleMaps


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Load API key from Config.plist
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["GOOGLE_MAPS_API_KEY"] as? String {
      GMSServices.provideAPIKey(apiKey)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
