//
//  KIOAPIConnection.m
//  BeaconConference
//
//  Created by Kirill Osipov on 21.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@import CoreLocation;


NSString *const kKIO_API_HOST = @"54.85.60.100";
NSString *const kKIO_API_ERROR_KEY = @"error";


#import "KIOAPIConnection.h"
#import "Reachability.h"


@implementation KIOAPIConnection

+ (instancetype)loadDataFrom:(NSURL *)dataURL mainQueue:(RequestAPIData)block
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    // TODO: locale
    // NSString *localeIdentifier = [[[NSLocale currentLocale] localeIdentifier] substringToIndex:2];
    
    Reachability *reachabilityHost = [Reachability reachabilityWithHostName:[dataURL host]];
    NetworkStatus reachabilityHostStatus = reachabilityHost.currentReachabilityStatus;
    
    if (reachabilityHostStatus == NotReachable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *error = @{kKIO_API_ERROR_KEY: @"Reachability Host Status is not reachable, this meens server host is not responced"};
            block(error, NO);
        });
    } else {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [[[NSURLSession sharedSession] dataTaskWithURL:dataURL
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         
                                         if (data && !error) {
                                             NSError *jsonError;
                                             NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                      options:NSJSONReadingAllowFragments
                                                                                                        error:&jsonError];
                                             if (!jsonError) {
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     if(block) block(jsonData, YES);
                                                     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                 });
                                             } else {
                                                 block(@{kKIO_API_ERROR_KEY: [jsonError localizedDescription]}, YES);
                                             }
                                         } else {
                                             block(@{kKIO_API_ERROR_KEY: [error localizedDescription]}, NO);
                                         }
                                         
                                     }] resume];
    }

    return sharedInstance;
}

@end
