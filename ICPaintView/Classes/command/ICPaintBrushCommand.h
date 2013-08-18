//
//  ICPaintStrokeCommand.h
//  ICPaintView
//
//  Created by Ichito Nagata on 2013/08/17.
//
//

#import <UIKit/UIKit.h>

#import "ICPaintCommand.h"

@interface ICPaintBrushCommand : ICPaintCommand

@property (nonatomic) UIColor *color;
@property (nonatomic) CGFloat size;
@property (nonatomic) NSString *textureName;

@end
