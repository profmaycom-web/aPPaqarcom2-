import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import FirebaseAuth
import awesome_notifications
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterStreamHandler {
  private let channelName = "app.channel.shared.data"
  private var initialLink: String?
  private var linkEventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDsuxFQVKBoURt070e56_GxUWDglHGTABC")


    SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
      SwiftAwesomeNotificationsPlugin.register(
        with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
    }

    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }


    storeInitialLink(from: launchOptions)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let methodChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "getInitialLink" else {
        result(FlutterMethodNotImplemented)
        return
      }

      result(self?.initialLink)
    }

    let eventChannel = FlutterEventChannel(
      name: "\(channelName)/link",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    eventChannel.setStreamHandler(self)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let firebaseAuth = Auth.auth()
    firebaseAuth.setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let firebaseAuth = Auth.auth()
    if firebaseAuth.canHandleNotification(userInfo) {
      print(userInfo)
      return
    }
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    handleIncomingLink(url)
    return super.application(app, open: url, options: options)
  }

  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if handle(userActivity: userActivity) {
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  private func storeInitialLink(from launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    if let url = launchOptions?[.url] as? URL {
      initialLink = url.absoluteString
      return
    }

    if let userActivity = launchOptions?[.userActivityType] as? NSUserActivity {
      _ = handle(userActivity: userActivity)
    }
  }

  private func handleIncomingLink(_ url: URL) {
    let link = url.absoluteString
    if let sink = linkEventSink {
      sink(link)
    } else {
      initialLink = link
    }
  }

  @discardableResult
  private func handle(userActivity: NSUserActivity) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
      return false
    }

    handleIncomingLink(url)
    return true
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    linkEventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    linkEventSink = nil
    return nil
  }
}
