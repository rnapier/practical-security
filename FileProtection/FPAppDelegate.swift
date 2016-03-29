//
//  FPAppDelegate.swift
//  FileProtection
//
//  Created by Rob Napier on 3/28/16.
//  Copyright © 2016 Rob Napier. All rights reserved.
//
//  Demonstrates various FileProtection settings
//  Only meaningful if run on a device that has a PIN lock
//  Install on device and run under Xcode to see log output.
//  Lock device when instructed.

import UIKit

final class FPAppDelegate: NSObject, UIApplicationDelegate  {

    var backgroundTask = UIBackgroundTaskInvalid

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        /*
         Normally it would be a good idea to call upgradeFilesInDirectory(_:error:) here, but
         we're deleting everything in the documents directory.
         */
        try! DocumentsDirectory.clean()

        /* Create a protected file */
        ProtectedFile.createWithOptions(.DataWritingFileProtectionComplete, name: "complete", shouldSucceed: true)

        print("Lock device now.")

        return true
    }

    private func endBackground() {
        UIApplication.sharedApplication().endBackgroundTask(self.backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }

    /*
     Called when protected data is going to be encrypted "soon." This is generally called
     as soon as the device is locked, but the data isn't really encrypted for 10 seconds.
     */
    func applicationProtectedDataWillBecomeUnavailable(application: UIApplication) {
        let delayInSeconds = Int64(11)
        print("Encrypting. Waiting \(delayInSeconds) seconds")

        backgroundTask = application.beginBackgroundTaskWithExpirationHandler {
            print("Failed to finish before we were killed.")
            self.endBackground()
        }

        let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * Int64(NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            print("Reading after encryption")

            /* Demonstrate failure when reading a protected file while we're locked */
            File.readForName("complete", shouldSucceed: false)

            /* Demonstrate failure trying to create a protected file while we're locked */
            ProtectedFile.createWithOptions(.DataWritingFileProtectionComplete, name: "complete-after-encryption", shouldSucceed: false)

            /* Demonstrate creating a protected file while locked using "...UnlessOpen" */
            ProtectedFile.createWithOptions(.DataWritingFileProtectionCompleteUnlessOpen, name: "complete-unless-open", shouldSucceed: true)

            print("Unlock device now")

            self.endBackground()
        }
    }

    /*
     Called when the device is unlocked and data is unencrypted. This is a good point to
     upgrade the encryption of any files you created while locked.
     */
    func applicationProtectedDataDidBecomeAvailable(application: UIApplication) {
        print("Upgrading files")
        Result.log( { try NSFileManager.defaultManager().upgradeFilesInDirectory(DocumentsDirectory.path) }, expectedResult: true)
        print("DONE")
    }

    private struct ProtectedFile {
        static func createWithOptions(options: NSDataWritingOptions, name: String, shouldSucceed: Bool) {
            let data = "This is some protected data".dataUsingEncoding(NSUTF8StringEncoding)!
            print("Creating '\(name). Should\(shouldSucceed ? "": " not") succeed.")
            Result.log({ try data.writeToFile(DocumentsDirectory.pathForName(name), options: options) }, expectedResult: shouldSucceed)
        }
    }

    private struct File {
        static func readForName(name: String, shouldSucceed: Bool) {
            print("Reading '\(name)'. Should\(shouldSucceed ? "" : " not") succeed.")
            Result.log({ let _ = try NSData(contentsOfFile: DocumentsDirectory.pathForName(name), options: []) }, expectedResult: shouldSucceed)
        }
    }

    private struct DocumentsDirectory {
        static let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        static func pathForName(name: String) -> String {
            return (DocumentsDirectory.path as NSString).stringByAppendingPathComponent(name)
        }
        static func clean() throws {
            let fm = NSFileManager.defaultManager()
            let dirEnum = fm.enumeratorAtPath(DocumentsDirectory.path)!
            while let filename = dirEnum.nextObject() as? String {
                print("Removing \(filename)")
                try fm.removeItemAtPath(pathForName(filename))
            }
        }
    }

    private struct Result {
        static func log(f: () throws -> Void, expectedResult expected: Bool) {
            if let _ = try? f() {
                print("Succeed \(expected ? "as expected." : "AND THIS WAS NOT EXPECTED.")")
            } else {
                print("Failed \(expected ? "AND THIS WAS NOT EXPECTED" : "as expected.")")
            }
        }
    }
}

/// Reusable code
extension NSFileManager {
    /**
     Upgrade all the files in the directory to NSFileProtectionComplete
     Keep going, even if some fail.
     Returns whether any failed, and provides the last error encountered
     */
    func upgradeFilesInDirectory(dir: String) throws {
        let desiredProtection = NSFileProtectionComplete

        let url = NSURL(fileURLWithPath: dir)

        guard let dirEnum = enumeratorAtURL(url, includingPropertiesForKeys: [NSFileProtectionKey], options: [], errorHandler: nil) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSURLErrorFailingURLErrorKey: url])
        }

        var lastError: ErrorType? = nil
        var resourceValue: AnyObject? = nil

        while let element = dirEnum.nextObject() as? NSURL {
            do {
                try element.getResourceValue(&resourceValue, forKey: NSFileProtectionKey)
                let currentProtection = resourceValue as? String ?? ""
                if currentProtection != desiredProtection {
                    try element.setResourceValue(desiredProtection, forKey: NSFileProtectionKey)
                }
            } catch {
                lastError = error
            }
        }
        
        if let lastError = lastError {
            throw lastError
        }
    }
}
