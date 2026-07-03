import UIKit
import TelegramUI
import BuildConfig
import ShareExtensionContext
import SwiftSignalKit
import TelegramCore

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

@objc(ShareRootController)
class ShareRootController: UIViewController {
    private var impl: ShareRootControllerImpl?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
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
            
            self.impl = ShareRootControllerImpl(initializationData: ShareRootControllerInitializationData(appBundleId: baseAppBundleId, appBuildType: buildConfig.isAppStoreBuild ? .public : .internal, appGroupPath: appGroupUrl.path, apiId: buildConfig.apiId, apiHash: buildConfig.apiHash, languagesCategory: languagesCategory, encryptionParameters: encryptionParameters, appVersion: appVersion, bundleData: buildConfig.bundleData(withAppToken: nil, tokenType: nil, tokenEnvironment: nil, signatureDict: nil), useBetaFeatures: !buildConfig.isAppStoreBuild, makeTempContext: { accountManager, appLockContext, applicationBindings, InitialPresentationDataAndSettings, networkArguments in
                return makeTempContext(
                    sharedContainerPath: appGroupUrl.path,
                    rootPath: rootPath,
                    appGroupPath: appGroupUrl.path,
                    accountManager: accountManager,
                    appLockContext: appLockContext,
                    encryptionParameters: EngineValueBoxEncryptionParameters(
                        forceEncryptionIfNoSet: false,
                        key: EngineValueBoxEncryptionParameters.Key(data: encryptionParameters.0)!,
                        salt: EngineValueBoxEncryptionParameters.Salt(data: encryptionParameters.1)!
                    ),
                    applicationBindings: applicationBindings,
                    initialPresentationDataAndSettings: InitialPresentationDataAndSettings,
                    networkArguments: networkArguments,
                    buildConfig: buildConfig
                )
            }), getExtensionContext: { [weak self] in
                return self?.extensionContext
            })
            
            self.impl?.openUrl = { [weak self] url in
                guard let self, let url = URL(string: url) else {
                    return
                }
                let _ = self.openURL(url)
            }
        }
        
        self.impl?.loadView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.impl?.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.impl?.viewWillDisappear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.impl?.viewWillDisappear()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.impl?.viewDidLayoutSubviews(view: self.view, traitCollection: self.traitCollection)
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(openURL(_:)), with: url) != nil
                }
            }
            responder = responder?.next
        }
        return false
    }
}
