//
//  KIOGeonamesAPI.m
//  Osipov_K_A_LW8
//
//  Created by Kirill Osipov on 07.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

NSString *const kKIOAPICashUUID = @"uuid_list.plist";
NSString *const kKIOAPICashData = @"uuid_data.plist";

static NSString *const kKIOAPIHost = @"54.85.60.100";


@import CoreLocation;

#import "KIOShchigelskyAPI.h"
#import "Reachability.h"


@implementation KIOShchigelskyAPI

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)loadBeaconListWithUpdateCash:(BOOL)isUpdate mainQueue:(void(^)(BOOL isDone))block
{
    NSString *cashFilePath = [self pathDataFile:kKIOAPICashUUID];
    
    // TODO: re_fuck
    // code dublicate hear
    
    if (isUpdate == NO && [[NSFileManager defaultManager] fileExistsAtPath:cashFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(YES);
        });
        
    } else {
        
        Reachability *geonamesReachability = [Reachability reachabilityWithHostName:kKIOAPIHost];
        NetworkStatus geonamesURLStatus = geonamesReachability.currentReachabilityStatus;
        
        if (geonamesURLStatus == NotReachable) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        } else {
            
            NSString *stringURL = [NSString stringWithFormat:@"http://%@/beaconsapp/uuids", kKIOAPIHost];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:stringURL]
                                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                                 
                                                                                 if (data && !error) {
                                                                                     
                                                                                     NSError *jsonError;
                                                                                     NSArray *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                                                                                     if (!jsonError) {
                                                                                         
                                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                                             [jsonData writeToFile:cashFilePath atomically:YES];
                                                                                             block(YES);
                                                                                             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                                                         });
                                                                                     } else NSLog(@"jsonError %@", [jsonError localizedDescription]);
                                                                                 } else NSLog(@"error %@", [error localizedDescription]);
                                                                             }];
            [downloadTask resume];
        }
    }
}

- (void)loadBeaconInfo:(CLBeacon *)beacon updateCash:(BOOL)isUpdate mainQueue:(void(^)(NSDictionary *dataFromAPI, BOOL isDone))block;
{
    NSString *cashFilePath = [self pathDataFile:kKIOAPICashData];
    
    if (isUpdate == NO && [[NSFileManager defaultManager] fileExistsAtPath:cashFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block([NSArray arrayWithContentsOfFile:cashFilePath], YES);
        });
        
    } else {
        
        // TODO: locale
        // NSString *localeIdentifier = [[[NSLocale currentLocale] localeIdentifier] substringToIndex:2];
        
        Reachability *geonamesReachability = [Reachability reachabilityWithHostName:kKIOAPIHost];
        NetworkStatus geonamesURLStatus = geonamesReachability.currentReachabilityStatus;
        
        if (geonamesURLStatus == NotReachable) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil, NO);
            });
        } else {
            
            NSString *stringURL = [self stringURLForBeacon:beacon];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:stringURL]
                                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                                 
                                                                                 if (data && !error) {
                                                                                     
                                                                                     NSError *jsonError;
                                                                                     NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                                                                                     if (!jsonError) {
                                                                                         
                                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                                             [jsonData writeToFile:cashFilePath atomically:YES];
                                                                                             block(jsonData, YES);
                                                                                             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                                                         });
                                                                                     } else NSLog(@"jsonError %@", [jsonError localizedDescription]);
                                                                                 } else NSLog(@"error %@", [error localizedDescription]);
                                                                             }];
            [downloadTask resume];
        }
    }
}

- (NSString *)stringURLForBeacon:(CLBeacon *)beacon
{
    NSString *hostAPI = [NSString stringWithFormat:@"http://%@/beaconsapp", kKIOAPIHost];
    NSString *stringURL = [NSString stringWithFormat:@"%@/object/%@/%@/%@", hostAPI, beacon.proximityUUID.UUIDString, beacon.minor, beacon.major];

    return stringURL;
}

- (void)deleteDataFile:(NSString *)fileName
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self pathDataFile:fileName]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self pathDataFile:fileName] error:nil];
    }
}

- (NSString *)pathDataFile:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [[paths firstObject] stringByAppendingPathComponent:fileName];
    return documentsPath;
}

@end
