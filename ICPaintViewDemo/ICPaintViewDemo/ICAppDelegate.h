//
//  ICAppDelegate.h
//  ICPaintViewDemo
//
//  Created by Ichito Nagata on 2013/08/17.
//  Copyright (c) 2013年 Ichito Nagata. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ICPaintViewDemoViewController;

@interface ICAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,retain) UINavigationController* navigationController;
@property (strong, nonatomic) ICPaintViewDemoViewController *viewController;

@end
