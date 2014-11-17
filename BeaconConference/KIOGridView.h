//
//  KIODrawingView.h
//  BeaconConference
//
//  Created by Kirill Osipov on 02.10.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@interface KIOGridView : UIView

@property (assign, nonatomic) int fieldSize;
@property (assign, nonatomic) CGFloat boardLineWidth;
@property (strong, nonatomic) UIColor *fieldColor;

@property (strong, nonatomic) NSDictionary *beaconPointWithColor;

@end
