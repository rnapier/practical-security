//
//  Connection.swift
//  SelfCert
//
//  Created by Rob Napier on 3/27/16.
//  Copyright © 2016 Rob Napier. All rights reserved.
//

import Foundation

class Connection: NSObject, NSURLSessionDelegate {

    let url = NSURL(string: "https://www.google.com")!

    lazy private var anchors: [SecCertificate] = {
        let path = NSBundle.mainBundle().pathForResource("www.google.com", ofType: "cer")!
        let certData = NSData(contentsOfFile: path)!
        let certificate = SecCertificateCreateWithData(nil, certData)!
        return [certificate]
    }()

    lazy private var session: NSURLSession = {
        return NSURLSession(configuration: .defaultSessionConfiguration(),
                            delegate: self,
                            delegateQueue: nil)
    }()

    override init() {
        super.init()

        let task = session.dataTaskWithURL(url) { (data, response, error) in
            if let error = error {
                print("Failed: \(error)")
            } else {
                print("Succeeded")
            }
        }
        task.resume()
    }

    func URLSession(session: NSURLSession,
                    didReceiveChallenge challenge: NSURLAuthenticationChallenge,
                                        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        let protectionSpace = challenge.protectionSpace

        if (protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {

            if let trust = protectionSpace.serverTrust {
                SecTrustSetAnchorCertificates(trust, anchors)
                SecTrustSetAnchorCertificatesOnly(trust, true)

                var result = SecTrustResultType(kSecTrustResultInvalid)
                let status = SecTrustEvaluate(trust, &result)

                if status == errSecSuccess {
                    switch Int(result) {
                    case kSecTrustResultProceed, kSecTrustResultUnspecified:
                        let cred = NSURLCredential(trust: trust)

                        completionHandler(.UseCredential, cred)
                        return

                    default:
                        print("Could not verify certificate: \(result)")
                    }
                }
            }

            // Something failed. Cancel
            completionHandler(.CancelAuthenticationChallenge, nil)

        } else {
            // We were asked for something other than server trust. Authenticate here if needed,
            // or call `completionHandler(.PerformDefaultHandling, nil)`
            preconditionFailure("Other authentication isn't implemented")
        }
    }
}