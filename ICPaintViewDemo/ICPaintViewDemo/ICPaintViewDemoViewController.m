//
//  ICPaintViewDemoViewController.m
//  ICPaintViewDemo
//
//  Created by Ichito Nagata on 2013/08/17.
//  Copyright (c) 2013年 Ichito Nagata. All rights reserved.
//

#import "ICPaintViewDemoViewController.h"

#import "ICPaintViewDemoCapturedImageViewController.h"

#import "ICPaintBrushCommand.h"
#import "ICPaintStampCommand.h"

@interface ICPaintViewDemoViewController ()

@end

@implementation ICPaintViewDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.paintView.delegate = self;    
    self.paintView.commandBuilder = self;
    [self.paintView setBrushColor:[UIColor colorWithRed:0.5 green:1 blue:1 alpha:0.2]];
    
    NSArray *textureNames = @[@"brush_glow", @"stamp_laughing_man_128"];
    for (NSString *textureName in textureNames) {
        [self.paintView addTextureImage:[UIImage imageNamed:textureName] forName:textureName];
    }
    
    self.mode = ICPaintViewDemoViewControllerModeBrush;

}

- (void) didBeginDrawing:(ICPaintView*)sender
{
    // write some code you like
}

- (void) didEndDrawing:(ICPaintView*)sender
{
    // write some code you like
}


- (IBAction)didModeButtonTapped:(id)sender
{
    if (self.mode == ICPaintViewDemoViewControllerModeBrush) {
        self.mode = ICPaintViewDemoViewControllerModeStamp;
        [self.modeButton setTitle:@"Stamp" forState:UIControlStateNormal];        
    } else if (self.mode == ICPaintViewDemoViewControllerModeStamp) {
        self.mode = ICPaintViewDemoViewControllerModeBrush;
        [self.modeButton setTitle:@"Brush" forState:UIControlStateNormal];
    }
}

- (IBAction)didCaptureButtonTapped:(id)sender
{
    UIImage *image = [self.paintView captureImage];
    
    ICPaintViewDemoCapturedImageViewController *controller = [[ICPaintViewDemoCapturedImageViewController alloc] initWithNibName:@"ICPaintViewDemoCapturedImageViewController" bundle:[NSBundle mainBundle]];
    [controller view];
    controller.capturedImageView.image = image;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)didUndoButtonTapped:(id)sender
{
    [self.paintView undo];
}

- (IBAction)didRedoButtonTapped:(id)sender
{
    [self.paintView redo];
}

- (ICPaintCommand*)buildCommand
{
    if (self.mode == ICPaintViewDemoViewControllerModeBrush) {
        ICPaintBrushCommand *command = [[ICPaintBrushCommand alloc] init];
        CGFloat r = (float)rand()/(float)RAND_MAX;
        CGFloat g = (float)rand()/(float)RAND_MAX;
        CGFloat b = (float)rand()/(float)RAND_MAX;
        UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:0.2];
        command.color = color;
        command.size = 32;
        command.textureName = @"brush_glow";
        return command;
        
    } else if (self.mode == ICPaintViewDemoViewControllerModeStamp) {
        ICPaintStampCommand *command = [[ICPaintStampCommand alloc] init];
        command.textureName = @"stamp_laughing_man_128";
        return command;
        
    } else {
        @throw @"don't reach";
    }

}



@end
