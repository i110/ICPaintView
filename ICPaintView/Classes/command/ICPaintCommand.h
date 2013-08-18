//
//  ICPaintCommand.h
//  ICPaintView
//
//  Created by Ichito Nagata on 2013/08/17.
//
//

#import <Foundation/Foundation.h>

#import "ICPaintView.h"

@interface ICPaintCommand : NSObject

@property (nonatomic, weak) ICPaintView *paintView;

- (void)prepare;
- (void)execute;
- (void)didTouchesBeginAtPoint:(CGPoint)point;
- (void)didTouchesMoveAtPoint:(CGPoint)point;
- (void)didTouchesEndAtPoint:(CGPoint)point;

@end
