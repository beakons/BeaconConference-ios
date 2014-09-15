//
//  KIOAPIConnection.m
//  BeaconConference
//
//  Created by Kirill Osipov on 21.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

NSString *const KIO_API_HOST = @"54.85.60.100";
NSString *const KIO_API_PORT = @"80";

NSString *const KIO_API_ERROR_DOMAIN = @"ru.beaconConference.error.domain";
NSString *const KIO_API_ERROR_DESCRIPTION_KEY = @"ru.beaconConference.error.key";

NSInteger const KIO_API_ERROR_CODE_HOST = 101;
NSInteger const KIO_API_ERROR_CODE_DATA = 102;


#import "KIOAPIConnection.h"
#import "Reachability.h"

@implementation KIOAPIConnection

+ (instancetype)performRequestWithURL:(NSURL *)dataURL
                   withLastUpdateTime:(NSDate *)lastUpdateTime
                         successBlock:(void(^)(NSData *data))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    // TODO: locale
    // NSString *localeIdentifier = [[[NSLocale currentLocale] localeIdentifier] substringToIndex:2];

    // TODO: lastUpdateTime
    // NSString *localeIdentifier = [[[NSLocale currentLocale] localeIdentifier] substringToIndex:2];
    
    Reachability *reachabilityHost = [Reachability reachabilityWithHostName:[dataURL host]];
    NetworkStatus reachabilityHostStatus = reachabilityHost.currentReachabilityStatus;
    
    if (reachabilityHostStatus == NotReachable) {
        
        NSString *errorString = [NSString stringWithFormat:@"Host %@ status is not responced", KIO_API_HOST];
        NSError *er = [NSError errorWithDomain:KIO_API_ERROR_DOMAIN
                                          code:KIO_API_ERROR_CODE_HOST
                                      userInfo:@{KIO_API_ERROR_DESCRIPTION_KEY : errorString}];

        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(er);
        });
        
    } else {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:dataURL
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    
                    if (data && !error) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            successBlock(data);
                            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        });
                        
                    } else {
                        
                        NSError *er =
                        [NSError errorWithDomain:KIO_API_ERROR_DOMAIN
                                            code:KIO_API_ERROR_CODE_DATA
                                        userInfo:@{KIO_API_ERROR_DESCRIPTION_KEY : [error localizedDescription]}];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            errorBlock(er);
                            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        });
                        
                    }
                }] resume];
    }
    
    return sharedInstance;
}


@end
