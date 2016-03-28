//
//  Connection.m
//  SelfCert
//
//  Created by Rob Napier on 11/25/12.
//  Copyright (c) 2012 Rob Napier. All rights reserved.
//

#import "Connection.h"

@interface Connection () <NSURLSessionDelegate>
@property (nonatomic, readwrite, strong) NSArray *anchors;
@property (nonatomic, readwrite, strong) NSURLSession *session;
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

        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        NSURLSessionDataTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:@"https://www.google.com"]
                                                 completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error){
                                                     if (error != nil) {
                                                         NSLog(@"Failed: %@", error);
                                                     } else {
                                                         NSLog(@"Succeeded");
                                                     }
                                                 }];

        [task resume];
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    SecTrustRef trust = challenge.protectionSpace.serverTrust;

    SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)self.anchors);
    SecTrustSetAnchorCertificatesOnly(trust, true);

    SecTrustResultType result;
    OSStatus status = SecTrustEvaluate(trust, &result);
    if (status == errSecSuccess &&
        (result == kSecTrustResultProceed ||
         result == kSecTrustResultUnspecified)) {
            
            NSURLCredential *cred = [NSURLCredential credentialForTrust:trust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
        }
    else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

@end
