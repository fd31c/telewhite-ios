import UIKit
import UserNotifications
import UserNotificationsUI
import TelegramUI
import BuildConfig

// Telewhite: resolve the app group container name that is actually provisioned.
// Re-signing services (ESign shared certs) often provision an app group named
// after their own App ID instead of group.<bundleId>. Try the conventional name
// first, then fall back to the groups listed in the embedded provisioning profile.
private func telewhiteResolvedAppGroupName(baseAppBundleId: String) -> String {
    let defaultName = "group.\(baseAppBundleId)"
    if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: defaultName) != nil {
        return defaultName
    }
    guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"), let raw = try? String(contentsOfFile: path, encoding: .isoLatin1) else {
        return defaultName
    }
    guard let keyRange = raw.range(of: "com.apple.security.application-groups") else {
        return defaultName
    }
    guard let arrayEndRange = raw.range(of: "</array>", range: keyRange.upperBound ..< raw.endIndex) else {
        return defaultName
    }
    var searchStart = keyRange.upperBound
    while let start = raw.range(of: "<string>", range: searchStart ..< arrayEndRange.lowerBound), let end = raw.range(of: "</string>", range: start.upperBound ..< arrayEndRange.lowerBound) {
        let candidate = String(raw[start.upperBound ..< end.lowerBound])
        if !candidate.isEmpty, FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: candidate) != nil {
            return candidate
        }
        searchStart = end.upperBound
    }
    return defaultName
}

@objc(NotificationViewController)
@available(iOSApplicationExtension 10.0, iOS 10.0, *)
class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private var impl: NotificationViewControllerImpl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.impl == nil {
            let appBundleIdentifier = Bundle.main.bundleIdentifier!
            guard let lastDotRange = appBundleIdentifier.range(of: ".", options: [.backwards]) else {
                return
            }
            
            let baseAppBundleId = String(appBundleIdentifier[..<lastDotRange.lowerBound])
            
            let buildConfig = BuildConfig(baseAppBundleId: baseAppBundleId)
            
            let languagesCategory = "ios"
            
            let appGroupName = telewhiteResolvedAppGroupName(baseAppBundleId: baseAppBundleId)
            let maybeAppGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
            
            guard let appGroupUrl = maybeAppGroupUrl else {
                return
            }
            
            let rootPath = appGroupUrl.path + "/telegram-data"
            
            let deviceSpecificEncryptionParameters = BuildConfig.deviceSpecificEncryptionParameters(rootPath, baseAppBundleId: baseAppBundleId)
            let encryptionParameters: (Data, Data) = (deviceSpecificEncryptionParameters.key, deviceSpecificEncryptionParameters.salt)
            
            let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"
            
            self.impl = NotificationViewControllerImpl(initializationData: NotificationViewControllerInitializationData(appBundleId: baseAppBundleId, appBuildType: buildConfig.isAppStoreBuild ? .public : .internal, appGroupPath: appGroupUrl.path, apiId: buildConfig.apiId, apiHash: buildConfig.apiHash, languagesCategory: languagesCategory, encryptionParameters: encryptionParameters, appVersion: appVersion, bundleData: buildConfig.bundleData(withAppToken: nil, tokenType: nil, tokenEnvironment: nil, signatureDict: nil), useBetaFeatures: !buildConfig.isAppStoreBuild), setPreferredContentSize: { [weak self] size in
                self?.preferredContentSize = size
            })
        }
        
        self.impl?.viewDidLoad(view: self.view)
    }
    
    func didReceive(_ notification: UNNotification) {
        self.impl?.didReceive(notification, view: self.view)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.impl?.viewWillTransition(to: size)
    }
}
