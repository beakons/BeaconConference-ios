//
//  KIOFirstViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 19.09.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#import "UIColor+Styling.h"
#import "CLBeacon+Helper.h"

#import "KIOBannerViewController.h"
#import "KIOAPIDataStore.h"
#import "KIOServiceController.h"
#import "KIOBeacon.h"

@interface KIOBannerViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (strong, nonatomic) UIView *tempView;


@property (strong, nonatomic) NSArray *beacons;

@end


@implementation KIOBannerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pageControl.numberOfPages = 0;
    
    KIOLog(@"viewDidLoad scrollView %@", NSStringFromCGRect(self.scrollView.frame));
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 
    KIOLog(@"viewDidAppear scrollView %@", NSStringFromCGRect(self.scrollView.frame));

    NSInteger svWidth = CGRectGetWidth(self.scrollView.frame);
    NSInteger svHeight = CGRectGetHeight(self.scrollView.frame);
    CGRect viewRect = CGRectMake(0, 0, svWidth, svHeight);
    
    self.tempView = [[UIView alloc] initWithFrame:viewRect];
    self.tempView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.1f];
    
    [self.scrollView addSubview:self.tempView];
    KIOLog(@"viewDidAppear tempView %@", NSStringFromCGRect(self.tempView.frame));
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notificationBeacons:)
               name:kKIOServiceBeaconsInRegionNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - NSNotification

- (void)notificationBeacons:(NSNotification *)notification
{
    self.beacons = (NSArray *)notification.userInfo[@"beacons"];
    [self reloadScrollView];
}


#pragma mark - UIScrollView Setup

- (void)setupScrollView:(UIScrollView *)scrollView
            withBeacons:(NSArray *)beacons
              viewBlock:(void(^)(CLBeacon *beacon, UIView *view))viewBlock
{
    NSInteger svWidth = CGRectGetWidth(scrollView.frame);
    NSInteger svHeight = CGRectGetHeight(scrollView.frame);
    
    for (CLBeacon *beacon in beacons) {
        
        CGFloat xOrigin = svWidth * [beacons indexOfObject:beacon];
        CGRect viewRect = CGRectMake(xOrigin, 0, svWidth, svHeight);
        
        UIView *view  = [[UIView alloc] initWithFrame:viewRect];
        view.frame = CGRectInset(view.frame, 10, 10);
        viewBlock(beacon, view);
        
        [scrollView addSubview:view];
    }
    
    scrollView.contentSize = CGSizeMake(svWidth * beacons.count, svHeight);
}

- (void)reloadScrollView
{
    for (UIView *view in self.scrollView.subviews) {
        if (![view isEqual:self.view]) {
            [view removeFromSuperview];
        }
    }
    
    [self setupScrollView:self.scrollView
              withBeacons:self.beacons
                viewBlock:^(CLBeacon *beacon, UIView *bannerView) {
                    
                    bannerView.backgroundColor = [UIColor proximityBeaconColor:beacon withAlphaComponent:.6f];
                    
                    CGRect lableRect = CGRectMake(0, CGRectGetMidY(bannerView.frame) - 20,
                                                  CGRectGetWidth(bannerView.frame), 20);
                    UILabel *lable = [[UILabel alloc] initWithFrame:lableRect];
                    lable.text = beacon.beaconID;
                    lable.textAlignment = NSTextAlignmentCenter;
                    
                    [bannerView addSubview:lable];
                  
              }];
    
    self.pageControl.numberOfPages = self.beacons.count;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat scrollViewWidth = CGRectGetWidth(scrollView.frame);
    NSInteger page = floor((scrollView.contentOffset.x - scrollViewWidth / 2) / scrollViewWidth) + 1;
    self.pageControl.currentPage = page;
}


@end
