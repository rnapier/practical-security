import UIKit

extension UIApplication {
    func applicationIdentifier() -> String {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "applicationIdentifierQuery",
            kSecAttrService as String: "",
            kSecReturnAttributes as String: true,
            ]

        var result: AnyObject? = nil
        var status = SecItemCopyMatching(query, &result)
        if status == errSecItemNotFound {
            status = SecItemAdd(query, &result)
        }
        precondition(status == errSecSuccess,
                     "Could not read or write to keychain: \(status)")

        guard let
            resultDictionary = result as? [String: AnyObject],
            accessGroup = resultDictionary[kSecAttrAccessGroup as String],
            identifier = accessGroup.componentsSeparatedByString(".").first
            else {
                preconditionFailure("Found garbage in keychain: \(result)")
        }

        return identifier
    }
}

let sharedKeychainIdentifier = "com.example.mygreatappsuite"
let applicationIdentifier = UIApplication.sharedApplication().applicationIdentifier()
let accessGroup = "\(applicationIdentifier).\(sharedKeychainIdentifier)"
