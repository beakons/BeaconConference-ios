//
//  CLBeacon+Helper.m
//  BeaconConference
//
//  Created by Kirill Osipov on 03.10.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#import "CLBeacon+Helper.h"

@implementation CLBeacon (Helper)

// identical KIOBeacon.h
- (NSString *)beaconID
{
    return [NSString stringWithFormat:@"mj%imn%i", [self.major intValue], [self.minor intValue]];
}


@end
