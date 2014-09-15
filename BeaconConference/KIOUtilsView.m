//
//  KIOUtilsView.m
//  BeaconConference
//
//  Created by Kirill Osipov on 20.08.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#import "KIOUtilsView.h"
#import "KIOUtils.h"


@interface KIOUtilsView ()
@property (nonatomic, strong) UITextView *consoleTextView;
@end


@implementation KIOUtilsView

+ (instancetype)turnON
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    CGRect consoleViewFrame = CGRectMake(window.bounds.origin.x,
                                         window.bounds.size.height/2,
                                         window.bounds.size.width,
                                         window.bounds.size.height/2);
    KIOUtilsView *utilsView = [[self alloc] initWithFrame:consoleViewFrame];
    [window addSubview:utilsView];

    return utilsView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];

    UILongPressGestureRecognizer *recognizer =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleKIOLog:)];
    recognizer.minimumPressDuration = 2.0f;
    [window addGestureRecognizer:recognizer];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:kKIOLogNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        
                        NSString *noteString = [self.consoleTextView.text stringByAppendingString:note.userInfo[kKIOLogNotificationUserInfo]];
                        self.consoleTextView.attributedText = [self coloredString:noteString];
                        [self setNeedsDisplay];

                    }];
    
    self.consoleTextView.hidden = NO;
    self.consoleTextView.backgroundColor = [UIColor blackColor];
    self.consoleTextView.alpha = 0.6f;
    self.consoleTextView.selectable = NO;
    self.consoleTextView.font = [UIFont systemFontOfSize:6.0f];
    
    [self addSubview:self.consoleTextView];
}


#pragma mark - Device Screen log

- (void)handleKIOLog:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.consoleTextView.hidden = self.consoleTextView.hidden ? NO : YES;
        KIOLog(@"LongPress hidden: %i", self.consoleTextView.hidden);
    }
}

- (NSAttributedString *)coloredString:(NSString *)inString
{
    NSMutableAttributedString *tempStr = [[NSMutableAttributedString alloc] initWithString:inString];
    
    NSArray *consoleRows = [inString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *consoleRow in consoleRows) {
        if ([consoleRow rangeOfString:@"error"].location != NSNotFound) {
            NSRange range = [inString rangeOfString:consoleRow];
            [tempStr addAttributes:@{NSForegroundColorAttributeName: [UIColor redColor],
                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:6.0f]} range:range];
        } else {
            NSRange range = [inString rangeOfString:consoleRow];
            [tempStr addAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor],
                                     NSFontAttributeName: [UIFont systemFontOfSize:6.0f]} range:range];
        }
    }
    
    return tempStr;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
