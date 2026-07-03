import UIKit
import UserNotifications
import UserNotificationsUI
import TelegramUI
import BuildConfig

// Telewhite: resolve the app group dynamically. Re-signing services replace the
// app group entitlement with certificate-specific identifiers (e.g. group.<id>.1),
// so the hardcoded "group.<bundle id>" container may be unavailable. Fall back to
// the first (alphabetically) accessible app group from the embedded provisioning
// profile, so the app and all extensions deterministically pick the same container.
private var telewhiteResolvedAppGroupNameValue: String?
private func telewhiteResolvedAppGroupName(baseAppBundleId: String) -> String {
    if let cached = telewhiteResolvedAppGroupNameValue {
        return cached
    }
    let defaultName = "group.\(baseAppBundleId)"
    var result = defaultName
    if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: defaultName) == nil {
        var profileGroups: [String] = []
        if let profilePath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"), let profileData = try? Data(contentsOf: URL(fileURLWithPath: profilePath)) {
            if let keyRange = profileData.range(of: Data("<key>com.apple.security.application-groups</key>".utf8)) {
                let searchUpperBound = min(profileData.count, keyRange.upperBound + 2048)
                let valueSlice = profileData.subdata(in: keyRange.upperBound ..< searchUpperBound)
                if let arrayEndRange = valueSlice.range(of: Data("</array>".utf8)) {
                    let arraySlice = valueSlice.subdata(in: 0 ..< arrayEndRange.lowerBound)
                    if let arrayText = String(data: arraySlice, encoding: .utf8) {
                        var remainder = arrayText[...]
                        while let startRange = remainder.range(of: "<string>"), let endRange = remainder.range(of: "</string>") {
                            if startRange.upperBound <= endRange.lowerBound {
                                profileGroups.append(String(remainder[startRange.upperBound ..< endRange.lowerBound]))
                            }
                            remainder = remainder[endRange.upperBound...]
                        }
                    }
                }
            }
        }
        for group in profileGroups.sorted() {
            if group.contains("*") {
                continue
            }
            if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) != nil {
                result = group
                break
            }
        }
    }
    telewhiteResolvedAppGroupNameValue = result
    return result
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
