//
//  KIOUtils.m
//  BeaconConference
//
//  Created by Kirill Osipov on 14.08.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#import "KIOUtils.h"

NSString *const kKIOLogNotification = @"ru.kirillosipov.kKIOLogNotification";
NSString *const kKIOLogNotificationUserInfo = @"ru.kirillosipov.kKIOLogNotificationUserInfo";

void KIOLog(NSString *format, ...) {
#if KIOLOG_DEDUG
   
    va_list args;
    va_start(args, format);
    
    NSLogv(format, args);
    
#if KIOLOG_DEDUG_NOTIFICATION

    NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kKIOLogNotification
                          object:nil
                        userInfo:@{kKIOLogNotificationUserInfo: log}];
    
#endif
    
    va_end(args);
#endif
}
