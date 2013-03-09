//
//  FPAppDelegate.m
//  FileProtection
//
//  Created by Rob Napier on 3/9/13.
//  Copyright (c) 2013 Rob Napier. All rights reserved.
//

#import "FPAppDelegate.h"


NSString *DocumentsDirectory() {
  return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

NSString *PathForName(NSString *name) {
  return [DocumentsDirectory() stringByAppendingPathComponent:name];
}

@interface FPAppDelegate ()
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@end

@implementation FPAppDelegate

- (void)readFileForName:(NSString *)name shouldSucceed:(BOOL)shouldSucceed
{
  NSData *data;
  NSError *error;

  NSLog(@"Reading '%@'. Should%@ succeed.", name, shouldSucceed ? @"" : @" not");
  data = [NSData dataWithContentsOfFile:PathForName(name)
                                options:0
                                  error:&error];
  [self logResult:(data != nil) expectedResult:shouldSucceed];
}

- (void)logResult:(BOOL)result expectedResult:(BOOL)expected
{
  if (result) {
    NSLog(@"Succeed %@", expected ? @"as expected." : @"AND THIS WAS NOT EXPECTED.");
  }
  else {
    NSLog(@"Failed %@", expected ? @"AND THIS WAS NOT EXPECTED" : @"as expected.");
  }
}

// Create a protected file.
- (void)createProtectedFileWithOptions:(enum NSDataWritingOptions)options name:(NSString *)name shouldSucceed:(BOOL)shouldSucceed
{
  NSData *data = [@"This is some protected data" dataUsingEncoding:NSUTF8StringEncoding];

  NSLog(@"Creating '%@'. Should%@ succeed.", name, shouldSucceed ? @"" : @" not");
  NSError *error;
  [self logResult:[data writeToFile:PathForName(name)
                            options:options
                              error:&error]
   expectedResult:shouldSucceed];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self cleanDocuments];
  [self createProtectedFileWithOptions:NSDataWritingFileProtectionComplete name:@"complete" shouldSucceed:YES];

  NSLog(@"Lock device now");

  return YES;
}

- (void)cleanDocuments
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:DocumentsDirectory()];
  for (NSString *path in dirEnum) {
    NSLog(@"Removing %@", path);
    [fm removeItemAtPath:[DocumentsDirectory() stringByAppendingPathComponent:path] error:NULL];
  }
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

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application
{
  NSLog(@"Upgrading files");
  NSError *error = nil;
  [self upgradeFilesInDirectory:DocumentsDirectory() error:&error];
  [self logResult:(error == nil) expectedResult:YES];
}

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
  double delayInSeconds = 11.0;
  NSLog(@"Encrypting. Waiting %.0f seconds", delayInSeconds);

  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
    NSLog(@"Reading after encryption");
    [self readFileForName:@"complete" shouldSucceed:NO];

    [self createProtectedFileWithOptions:NSDataWritingFileProtectionComplete name:@"complete-after-encryption" shouldSucceed:NO];
    [self createProtectedFileWithOptions:NSDataWritingFileProtectionCompleteUnlessOpen name:@"complete-unless-open" shouldSucceed:YES];

    [application endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
  });
}

- (void)upgradeFilesInDirectory:(NSString *)dir
                          error:(NSError **)error
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:dir];
  for (NSString *path in dirEnum) {
    NSDictionary *attrs = [dirEnum fileAttributes];
    if (![[attrs objectForKey:NSFileProtectionKey] isEqual:NSFileProtectionComplete]) {
      [fm setAttributes:@{NSFileProtectionKey : NSFileProtectionComplete}
           ofItemAtPath:[DocumentsDirectory() stringByAppendingPathComponent:path]
                  error:error];
    }
  }
}

@end
