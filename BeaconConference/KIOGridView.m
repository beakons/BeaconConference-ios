//
//  KIODrawingView.m
//  BeaconConference
//
//  Created by Kirill Osipov on 02.10.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#import "KIOGridView.h"

@implementation KIOGridView

- (void)drawRect:(CGRect)rect
{
    CGFloat offSet = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    CGFloat maxBoardSize = MIN(CGRectGetWidth(rect) - offSet*2,
                               CGRectGetHeight(rect) - offSet*2);

    int cellSize = (int)maxBoardSize / _fieldSize;
    int boardSize = cellSize * _fieldSize;
    
    CGRect boardRect = CGRectMake((CGRectGetWidth(rect) - boardSize) / 2,
                                  (CGRectGetHeight(rect) - boardSize) / 2,
                                  boardSize, boardSize);
    
    boardRect = CGRectIntegral(boardRect);

    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSMutableSet *cellRects = [NSMutableSet setWithCapacity:_fieldSize * _fieldSize];
    NSMutableDictionary *beaconRects = [NSMutableDictionary dictionaryWithCapacity:_beaconPointWithColor.count];
    BOOL checkPosition = _beaconPointWithColor.count > 0;

    for (int i=0; i<_fieldSize; i++) {
        for (int j=0; j<_fieldSize; j++) {
            
            CGRect cellRect = CGRectMake(CGRectGetMinX(boardRect) + i*cellSize,
                                         CGRectGetMinY(boardRect) + j*cellSize,
                                         cellSize, cellSize);
            [cellRects addObject:[NSValue valueWithCGRect:cellRect]];
            
            if (checkPosition) {
                for (NSString *beaconStringPoint in _beaconPointWithColor) {
                    CGPoint beaconPoint = CGPointFromString(beaconStringPoint);
                    if (((int)beaconPoint.x == i) && ((int)beaconPoint.y == j)) {
                        [beaconRects setObject:_beaconPointWithColor[beaconStringPoint]
                                        forKey:NSStringFromCGRect(cellRect)];
                    }
                }
            }
        }
    }
    
    // grid
    for (NSValue *rect in cellRects) {
        CGContextAddRect(context, [rect CGRectValue]);
    }
    CGContextSetStrokeColorWithColor(context, _fieldColor ? _fieldColor.CGColor : [UIColor lightGrayColor].CGColor);
    CGContextSetLineWidth(context, _boardLineWidth ? _boardLineWidth : 1.f);
    CGContextStrokePath(context);

    // beacons
    if (beaconRects.count > 0) {
        for (NSString *cellStringRect in beaconRects) {
            CGContextAddRect(context, CGRectFromString(cellStringRect));
            CGContextSetFillColorWithColor(context, [(UIColor *)beaconRects[cellStringRect] CGColor]);
            CGContextFillPath(context);
        }
    }
}

@end
