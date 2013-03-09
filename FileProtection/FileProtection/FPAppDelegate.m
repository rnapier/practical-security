//
//  FPAppDelegate.m
//  FileProtection
//
//  Created by Rob Napier on 3/9/13.
//  Copyright (c) 2013 Rob Napier. All rights reserved.
//

#import "FPAppDelegate.h"


@interface FPAppDelegate ()
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@end

@implementation FPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  /*
   Normally it would be a good idea to call -upgradeFilesInDirectory:error: here, but
   we're deleting everything in the documents directory.
   */
  [self cleanDocuments];

  /* Create a protected file */
  [self createProtectedFileWithOptions:NSDataWritingFileProtectionComplete
                                  name:@"complete"
                         shouldSucceed:YES];

  NSLog(@"Lock device now.");

  return YES;
}

/*
 Creating a protected file
 */

- (void)createProtectedFileWithOptions:(enum NSDataWritingOptions)options
                                  name:(NSString *)name
                         shouldSucceed:(BOOL)shouldSucceed {
  NSData *data = [@"This is some protected data" dataUsingEncoding:NSUTF8StringEncoding];

  NSLog(@"Creating '%@'. Should%@ succeed.", name, shouldSucceed ? @"" : @" not");
  NSError *error;
  [self logResult:[data writeToFile:PathForName(name)
                            options:options
                              error:&error]
   expectedResult:shouldSucceed];
}

/*
 Called when protected data is going to be encrypted "soon." This is generally called
 as soon as the device is locked, but the data isn't really encrypted for 10 seconds.
 */
- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
  double delayInSeconds = 11.0;
  NSLog(@"Encrypting. Waiting %.0f seconds", delayInSeconds);

  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                          (uint64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
    NSLog(@"Reading after encryption");

    /* Demonstrate failure when reading a protected file while we're locked */
    [self readFileForName:@"complete" shouldSucceed:NO];

    /* Demonstrate failure trying to create a protected file while we're locked */
    [self createProtectedFileWithOptions:NSDataWritingFileProtectionComplete
                                    name:@"complete-after-encryption"
                           shouldSucceed:NO];

    /* Demonstrate creating a protected file while locked using "...UnlessOpen" */
    [self createProtectedFileWithOptions:NSDataWritingFileProtectionCompleteUnlessOpen
                                    name:@"complete-unless-open"
                           shouldSucceed:YES];

    [application endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
  });
}

/*
 Called when the device is unlocked and data is unencrypted. This is a good point to
 upgrade the encryption of any files you created while locked.
 */
- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
  NSLog(@"Upgrading files");
  NSError *error = nil;
  [self upgradeFilesInDirectory:DocumentsDirectory() error:&error];
  [self logResult:(error == nil) expectedResult:YES];
}


/* 
 Simple implementation of upgrading the file protections to "complete." This 
 implementation upgrades everything in the Documents directory.
 */
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

/**********************************************************************/
/*
 Helper methods. Things below here have fairly obvious implementations.
 */

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

NSString *DocumentsDirectory() {
  return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

NSString *PathForName(NSString *name) {
  return [DocumentsDirectory() stringByAppendingPathComponent:name];
}

@end
