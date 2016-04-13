//
//  main.swift
//  hash
//
//  Created by Rob Napier on 4/10/16.
//  Copyright © 2016 Rob Napier. All rights reserved.
//

import Foundation

let hashPrefix = "com.example.MyGreatApp" // Not a secret, but should be unique to you

func hashedPasswordForUsername(username: String, password: String) -> NSData {

    // Scale rounds based on your hardware. 10k for iPhone 4. Otherwise 100k.
    let rounds = UInt32(100_000)

    // This can be just about anything "long enough." 256-bits is nice.
    let hashLength = Int(CC_SHA256_DIGEST_LENGTH)

    // Construct our salt from the prefix and username
    let salt = "\(hashPrefix):\(username)".dataUsingEncoding(NSUTF8StringEncoding)!

    // Convert our password into data
    let passwordData = password.dataUsingEncoding(NSUTF8StringEncoding)!

    // The final result storage
    let hash = NSMutableData(length: hashLength)!

    // Perform the hash
    let result = CCKeyDerivationPBKDF(
        CCPBKDFAlgorithm(kCCPBKDF2),
        UnsafePointer(passwordData.bytes), passwordData.length,
        UnsafePointer(salt.bytes), salt.length,
        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), rounds,
        UnsafeMutablePointer(hash.mutableBytes), hash.length)

    guard result == CCCryptorStatus(kCCSuccess) else {
        fatalError("Could not derive hash for user: \(username) (\(result))")
    }
    return hash
}
