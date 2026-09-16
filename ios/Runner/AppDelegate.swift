import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static var isChannelRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    AppDelegate.registerShareChannel(with: engineBridge.applicationRegistrar.messenger())
  }

  private static func registerShareChannel(with messenger: FlutterBinaryMessenger) {
    guard !isChannelRegistered else { return }
    isChannelRegistered = true

    let shareChannel = FlutterMethodChannel(
      name: "com.tvr.ecommerce/file_share",
      binaryMessenger: messenger
    )
    shareChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "shareFile" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "File path missing", details: nil))
          return
        }

        DispatchQueue.main.async {
          guard let topVC = AppDelegate.topViewController() else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Cannot find top view controller", details: nil))
            return
          }

          let fileUrl = URL(fileURLWithPath: filePath)
          let activityVC = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
          if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
          }
          topVC.present(activityVC, animated: true) {
            result(true)
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let baseVC: UIViewController?
    if let base = base {
      baseVC = base
    } else {
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      let keyWindow = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
      baseVC = keyWindow?.rootViewController ?? scenes.first?.windows.first?.rootViewController
    }

    if let nav = baseVC as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = baseVC as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = baseVC?.presentedViewController {
      return topViewController(base: presented)
    }
    return baseVC
  }
}
