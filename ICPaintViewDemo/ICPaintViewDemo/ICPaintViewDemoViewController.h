//
//  ICPaintViewDemoViewController.h
//  ICPaintViewDemo
//
//  Created by Ichito Nagata on 2013/08/17.
//  Copyright (c) 2013年 Ichito Nagata. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ICPaintView.h"



typedef enum {
    ICPaintViewDemoViewControllerModeBrush = 1,
    ICPaintViewDemoViewControllerModeStamp = 2,
} ICPaintViewDemoViewControllerMode;

@interface ICPaintViewDemoViewController : UIViewController
<ICPaintViewDelegate, ICPaintCommandBuilder>

@property (nonatomic) ICPaintViewDemoViewControllerMode mode;

@property (nonatomic, weak) IBOutlet ICPaintView *paintView;
@property (nonatomic, weak) IBOutlet UIButton *modeButton;
@property (nonatomic, weak) IBOutlet UIButton *captureButton;
@property (nonatomic, weak) IBOutlet UIButton *undoButton;
@property (nonatomic, weak) IBOutlet UIButton *redoButton;

- (IBAction)didModeButtonTapped:(id)sender;
- (IBAction)didCaptureButtonTapped:(id)sender;
- (IBAction)didUndoButtonTapped:(id)sender;
- (IBAction)didRedoButtonTapped:(id)sender;
- (IBAction)didStampButtonTapped:(id)sender;

@end
