//
//  FPAppDelegate.m
//  FileProtection
//
//  Created by Rob Napier on 3/9/13.
//  Copyright (c) 2013 Rob Napier. All rights reserved.
//

#import "FPAppDelegate.h"



NSString * DocumentsDirectory() {
  return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

}

void ReadPath(NSString *path, NSString *name) {
  NSData *data;
  NSError *error;

  NSLog(@"Reading '%@'", name);
  data = [NSData dataWithContentsOfFile:path
                                options:0
                                  error:&error];
  if (data)
  {
    NSLog(@"Success.");
  }
  else{
    NSLog(@"Failed: %@", error);
  }
}

@interface FPAppDelegate ()
@property (nonatomic, readonly) NSString *completeProtectionPath;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@end

@implementation FPAppDelegate

- (id)init
{
  self = [super init];
  if (self) {
    _completeProtectionPath = [DocumentsDirectory() stringByAppendingPathComponent:@"protected.dat"];
  }

  return self;
}

// Create a protected file.
- (void)createProtectedFileAtPath:(NSString *)path
{
  NSData *data = [@"This is some protected data" dataUsingEncoding:NSUTF8StringEncoding];

  NSLog(@"Creating 'Complete'");
  NSError *error;
  if ([data writeToFile:path
                options:NSDataWritingFileProtectionComplete
                  error:&error])
  {
    NSLog(@"Success");
  }
  else
  {
    NSLog(@"Failed to write: %@", error);
  }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self createProtectedFileAtPath:self.completeProtectionPath];

  return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
    NSLog(@"Failed to finish before we were killed.");
    [application endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
  }];

  NSLog(@"Entering background");
}

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
  double delayInSeconds = 11.0;
  NSLog(@"Encrypting. Waiting %.0f seconds", delayInSeconds);

  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
    NSLog(@"Reading after encryption");
    ReadPath(self.completeProtectionPath, @"Complete");

    [application endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
  });
  
  
}


@end
