import Flutter
import UIKit

public class UpiIntentPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "upi_intent", binaryMessenger: registrar.messenger())
        let instance = UpiIntentPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInstalledUpiApps":
            handleGetInstalledApps(result: result)
        case "launchUpiApp":
            guard let args = call.arguments as? [String: Any],
                  let upiUrl = args["upiUrl"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "upiUrl is required", details: nil))
                return
            }
            handleLaunchUpiApp(upiUrl: upiUrl, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Get Installed UPI Apps
    
    /// Returns installed UPI-capable apps on iOS
    /// Note: iOS has limited app discovery due to sandboxing.
    /// We check known URL schemes for popular UPI apps.
    private func handleGetInstalledApps(result: @escaping FlutterResult) {
        let upiApps: [(name: String, packageName: String, scheme: String)] = [
            ("Google Pay", "com.google.GooglePayIndia", "gpay://"),
            ("PhonePe", "com.phonepe.PhonePeApp", "phonepe://"),
            ("Paytm", "net.one97.paytm", "paytmmp://"),
            ("Amazon Pay", "com.amazon.AmazonIN", "amznmobile://"),
            ("BHIM", "in.gov.uidai.BHIMApp", "bhim://"),
        ]
        
        var installedApps: [[String: Any]] = []
        
        for app in upiApps {
            if let url = URL(string: app.scheme),
               UIApplication.shared.canOpenURL(url) {
                installedApps.append([
                    "name": app.name,
                    "packageName": app.packageName,
                    "icon": FlutterStandardTypedData(bytes: Data()) // iOS doesn't give app icons
                ])
            }
        }
        
        result(installedApps)
    }
    
    // MARK: - Launch UPI App
    
    private func handleLaunchUpiApp(upiUrl: String, result: @escaping FlutterResult) {
        guard let url = URL(string: upiUrl) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid UPI URL: \(upiUrl)", details: nil))
            return
        }
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        // iOS doesn't return transaction data like Android.
                        // Return a pending status — the app must verify via backend.
                        result("Status=pending")
                    } else {
                        result(FlutterError(
                            code: "LAUNCH_FAILED",
                            message: "Failed to open UPI URL",
                            details: nil
                        ))
                    }
                }
            } else {
                result(FlutterError(
                    code: "NO_APP",
                    message: "No UPI app found that can handle this URL",
                    details: nil
                ))
            }
        }
    }
}
