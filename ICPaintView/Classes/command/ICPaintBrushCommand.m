//
//  ICPaintStrokeCommand.m
//  ICPaintView
//
//  Created by Ichito Nagata on 2013/08/17.
//
//

#import "ICPaintBrushCommand.h"

@interface ICPaintBrushCommand ()
{
    NSMutableArray *_points;
}
@end

@implementation ICPaintBrushCommand

- (id)init
{
    self = [super init];
    if (self) {
        _points = [NSMutableArray new];
    }
    return self;
}


- (void)execute
{
    if (_points.count == 1) {
        CGPoint from = [[_points objectAtIndex:0] CGPointValue];
        CGPoint to   = from;
        [self.paintView drawLineFromPoint:from toPoint:to];
    } else {
        for (int i = 1; i < _points.count; i++) {
            CGPoint from = [[_points objectAtIndex:(i - 1)] CGPointValue];
            CGPoint to   = [[_points objectAtIndex:i]       CGPointValue];
            [self.paintView drawLineFromPoint:from toPoint:to];
        }
    }
}

- (void)prepare
{
    [self.paintView useShader:ICPaintViewShaderPoint];
    [self.paintView setCurrentTexture:self.textureName];
    [self.paintView setBrushSize:self.size];
    [self.paintView setBrushColor:self.color];
}

- (void)didTouchesBeginAtPoint:(CGPoint)point
{
    [_points addObject:[NSValue valueWithCGPoint:point]];
    [self.paintView drawLineFromPoint:point toPoint:point];
    [self.paintView render];
}

- (void)didTouchesMoveAtPoint:(CGPoint)point
{
    CGPoint lastPoint;
    NSValue *lastPointValue = [_points lastObject];
    if (lastPointValue) {
        lastPoint = [lastPointValue CGPointValue];
    } else {
        lastPoint = point;
    }
    [_points addObject:[NSValue valueWithCGPoint:point]];
    [self.paintView drawLineFromPoint:lastPoint toPoint:point];
    [self.paintView render];
}

- (void)didTouchesEndAtPoint:(CGPoint)point
{
    // do nothing
}

@end
