//
//  Connection.m
//  SelfCert
//
//  Created by Rob Napier on 11/25/12.
//  Copyright (c) 2012 Rob Napier. All rights reserved.
//

#import "Connection.h"

@interface Connection () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, readwrite, strong) NSArray *anchors;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@end

@implementation Connection

- (id)init {
  self = [super init];
  if (self) {
    NSError *error = NULL;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"www.google.com"
                                                     ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:path
                                              options:0
                                                error:&error];
    
    if (! certData) {
      // Handle error reading
    }
    
    SecCertificateRef
    certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
    
    if (!certificate) {
      // Handle error parsing
    }
    
    self.anchors = [NSArray arrayWithObject:CFBridgingRelease(certificate)];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:
                       [NSURLRequest requestWithURL:
                        [NSURL URLWithString:@"https://www.google.com"]] delegate:self];
  }
  return self;
}

- (void)connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

  SecTrustRef trust = challenge.protectionSpace.serverTrust;
  
  SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)self.anchors);
  SecTrustSetAnchorCertificatesOnly(trust, true);
  
  SecTrustResultType result;
  OSStatus status = SecTrustEvaluate(trust, &result);
  if (status == errSecSuccess &&
      (result == kSecTrustResultProceed ||
       result == kSecTrustResultUnspecified)) {

    NSURLCredential *cred = [NSURLCredential credentialForTrust:trust];
    [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
  }
  else {
    [challenge.sender cancelAuthenticationChallenge:challenge];
  }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  NSLog(@"Failed: %@", error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSLog(@"Succeeded");
}



@end
