//
//  KIOAPIConnection.h
//  BeaconConference
//
//  Created by Kirill Osipov on 21.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

extern NSString *const KIO_API_HOST;
extern NSString *const KIO_API_PORT;

extern NSString *const KIO_API_ERROR_DOMAIN;
extern NSString *const KIO_API_ERROR_DESCRIPTION_KEY;

extern NSInteger const KIO_API_ERROR_CODE_HOST;
extern NSInteger const KIO_API_ERROR_CODE_DATA;


@interface KIOAPIConnection : NSObject

+ (instancetype)performRequestWithURL:(NSURL *)dataURL
                   withLastUpdateTime:(NSDate *)lastUpdateTime
                         successBlock:(void(^)(NSData *data))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

@end
