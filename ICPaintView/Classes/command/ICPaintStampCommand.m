//
//  ICPaintStampCommand.m
//  ICPaintView
//
//  Created by Ichito Nagata on 2013/08/18.
//
//

#import "ICPaintStampCommand.h"


@interface ICPaintStampCommand ()
{
    CGPoint _point;
}
@end

@implementation ICPaintStampCommand

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


- (void)execute
{
    [self drawAtPoint:_point];
}

- (void)prepare
{
    [self.paintView useShader:ICPaintViewShaderImage];
    [self.paintView setCurrentTexture:self.textureName];
}

- (void)drawAtPoint:(CGPoint)point;
{
    UIImage *textureImage = [self.paintView textureImageForName:self.textureName];
    CGFloat w = textureImage.size.width;
    CGFloat h = textureImage.size.height;
    CGFloat x = point.x - (w / 2);
    CGFloat y = point.y - (h / 2);
    [self.paintView drawTextureToRect:CGRectMake(x, y, w, h)];
}

- (void)didTouchesBeginAtPoint:(CGPoint)point
{
    _point = point;
    [self drawAtPoint:point];
    [self.paintView render];
}

- (void)didTouchesMoveAtPoint:(CGPoint)point
{
    // do nothing
}

- (void)didTouchesEndAtPoint:(CGPoint)point
{
    // do nothing
}

@end