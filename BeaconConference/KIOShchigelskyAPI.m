//
//  KIOShchigelskyAPI.m
//  BeaconConference
//
//  Created by Kirill Osipov on 07.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

NSString *const kKIO_API_CASH_UUID_FILE = @"uuid_list.plist";
NSString *const kKIO_API_CASH_DATA_FILE = @"uuid_data.plist";
NSString *const kKIO_API_CONST_UUIDS = @"uuids";

static NSString *const kKIO_API_HOST = @"54.85.60.100";

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

- (void)loadUUIDReloadCash:(BOOL)update mainQueue:(void(^)(BOOL success))block
{
    NSString *cashFilePath = [self pathDataFile:kKIO_API_CASH_UUID_FILE];
    
    if (update == NO && [[NSFileManager defaultManager] fileExistsAtPath:cashFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(YES);
        });
        
    } else {

        NSString *stringURL = [NSString stringWithFormat:@"http://%@/beaconsapp/uuids", kKIO_API_HOST];
        [self loadDataFrom:[NSURL URLWithString:stringURL] mainQueue:^(NSDictionary *dataFromAPI, BOOL success) {
            
            [dataFromAPI writeToFile:cashFilePath atomically:YES];
            block(success);
        }];
    }
}

- (void)loadBeacon:(CLBeacon *)beacon reloadCash:(BOOL)update mainQueue:(void(^)(NSDictionary *dataFromAPI, BOOL success))block
{
    NSString *cashFilePath = [self pathDataFile:kKIO_API_CASH_DATA_FILE];
    
    if (update == NO && [[NSFileManager defaultManager] fileExistsAtPath:cashFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block([NSDictionary dictionaryWithContentsOfFile:cashFilePath], YES);
        });
        
    } else {
        
        NSURL *url = [self URLBeacon:beacon];
        [self loadDataFrom:url mainQueue:^(NSDictionary *dataFromAPI, BOOL success) {
            
            // TODO: data cash file
            [dataFromAPI writeToFile:cashFilePath atomically:YES];
            
            block(dataFromAPI, success);
        }];
    }
}

- (void)deleteDataFile:(NSString *)fileName
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self pathDataFile:fileName]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self pathDataFile:fileName] error:nil];
    }
}

- (BOOL)cashExists:(NSString *)fileName
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self pathDataFile:fileName]];
}

- (NSString *)pathDataFile:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [[paths firstObject] stringByAppendingPathComponent:fileName];
    return documentsPath;
}


#pragma mark - Privat RequestAPIData

typedef void (^RequestAPIData)(NSDictionary *dataFromAPI, BOOL success);

- (void)loadDataFrom:(NSURL *)dataURL mainQueue:(RequestAPIData)block
{
    // TODO: locale
    // NSString *localeIdentifier = [[[NSLocale currentLocale] localeIdentifier] substringToIndex:2];
    
    Reachability *reachabilityHost = [Reachability reachabilityWithHostName:[dataURL host]];
    NetworkStatus reachabilityHostStatus = reachabilityHost.currentReachabilityStatus;
    
    if (reachabilityHostStatus == NotReachable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(nil, NO);
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
                                                     block(jsonData, YES);
                                                     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                 });
                                             } else NSLog(@"SerializationJSONError: %@", [jsonError localizedDescription]);
                                         } else NSLog(@"URLSessionError: %@", [error localizedDescription]);
                                         
                                     }] resume];
    }
}

- (NSURL *)URLBeacon:(CLBeacon *)beacon
{
    NSString *hostAPI = [NSString stringWithFormat:@"http://%@/beaconsapp", kKIO_API_HOST];
    NSString *stringURL = [NSString stringWithFormat:@"%@/object/%@/%@/%@", hostAPI, [beacon.proximityUUID.UUIDString lowercaseString], beacon.major, beacon.minor];
    
    return [NSURL URLWithString:stringURL];
}

@end
