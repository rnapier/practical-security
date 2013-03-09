//
//  AppDelegate.m
//  CompleteUnlessOpen
//
//  Created by Rob Napier on 3/9/13.
//  Copyright (c) 2013 Rob Napier. All rights reserved.
//
//  Demonstrates changing file protections on a logfile so that it is as protected as it
//  can be when the device is locked or unlocked.

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic, readwrite, strong) dispatch_block_t loggerBlock;
@property (nonatomic, readwrite, assign) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, readwrite, copy) NSString *logPath;
@end

@implementation AppDelegate

- (void)setLogFileProtection:(NSString *)protection
{
  NSError *error;
  if (! [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey : protection}
                                         ofItemAtPath:self.logPath
                                                error:&error]) {
    NSLog(@"Could not set file protection: %@", error);
  }
}

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
  NSLog(@"%s", __PRETTY_FUNCTION__);

  [self setLogFileProtection:NSFileProtectionCompleteUnlessOpen];
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
  NSLog(@"%s", __PRETTY_FUNCTION__);

  [self setLogFileProtection:NSFileProtectionCompleteUnlessOpen];
}

- (void)startLogger
{
  self.logPath = [DocumentsDirectory() stringByAppendingPathComponent:@"log.txt"];
  NSOutputStream *logStream = [NSOutputStream outputStreamToFileAtPath:self.logPath append:YES];
  [logStream open];

  [self setLogFileProtection:NSFileProtectionComplete];

  __weak typeof(self) weakSelf = self;
  dispatch_block_t loggerBlock = ^{
    NSString *logEntry = [[[NSDate date] description] stringByAppendingString:@"\n"];
    if ([logStream write:(const uint8_t *)[logEntry UTF8String]
             maxLength:[logEntry lengthOfBytesUsingEncoding:NSUTF8StringEncoding]] == -1)
    {
      NSLog(@"Could not write to logfile: %@", [logStream streamError]);
    }
    else
    {
      NSLog(@"Logged");
    }

    dispatch_block_t loopBlock = weakSelf.loggerBlock;
    if (loopBlock) {
      double delayInSeconds = 2.0;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
      dispatch_after(popTime, dispatch_get_main_queue(), loopBlock);
    }
    else {
      NSLog(@"Logger stopped");
    }
  };

  self.loggerBlock = loggerBlock;

  dispatch_async(dispatch_get_main_queue(), loggerBlock);
}

- (void)stopLogger
{
  self.loggerBlock = nil;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self startLogger];

  NSLog(@"Lock device now");
  // Override point for customization after application launch.
  return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
  // Keep running until the OS kills us.
  self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
    NSLog(@"Failed to finish before we were killed.");
    [application endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
  }];

}

NSString *DocumentsDirectory() {
  return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

@end
