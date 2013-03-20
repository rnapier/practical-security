//
//  AppDelegate.m
//  Hashing
//
//  Created by Rob Napier on 3/11/13.
//  Copyright (c) 2013 Rob Napier. All rights reserved.
//

#import "AppDelegate.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation AppDelegate

- (NSData *)hashedPasswordForUsername:(NSString *)username password:(NSString *)password {

  // This is not a secret, but it should be unique to you
  // Random would be more secure, but is a headache if you want to login from multiple devices.
  static NSString *kHashPrefix = @"com.example.MyGreatApp\0";

  // Scale rounds based on your hardware. If an iPhone 4 needs to be involved, then 10k is
  // 80ms and makes a reasonable compromise. If you don't need anything as slow as an
  // iPhone 4, use 100k
  static uint kRounds = 1;

  // This can be just about anything "long enough." 256-bits is nice.
  static size_t kKeyLength = CC_SHA256_DIGEST_LENGTH;


  NSData *salt = [[@[kHashPrefix, username] componentsJoinedByString:@""]
                          dataUsingEncoding:NSUTF8StringEncoding];
  
  NSMutableData *key = [NSMutableData dataWithLength:kKeyLength];
  NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
  
  CCKeyDerivationPBKDF(kCCPBKDF2,             // algorithm
                       [passwordData bytes],  // password
                       [passwordData length], // passwordLen
                       [salt bytes],          // salt
                       [salt length],         // saltLen
                       kCCPRFHmacAlgSHA256,   // prf
                       kRounds,               // rounds
                       [key mutableBytes],    // *derivedKey
                       [key length]);         // keyLength

  return key;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  NSLog(@"%@", [self hashedPasswordForUsername:@"someone" password:@"mypassword"]);
  return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
