//
//  ICPaintView.h
//  Pods
//
//  Created by Ichito Nagata on 2013/08/17.
//
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>



typedef enum {
    ICPaintViewShaderPoint = 0,
    ICPaintViewShaderImage = 1,
} ICPaintViewShader;

typedef struct {
    GLuint id;
    GLsizei width, height;
} textureInfo_t;

@class ICPaintView;
@protocol ICPaintViewDelegate <NSObject>
@optional
- (void) didBeginDrawing:(ICPaintView*)sender;
- (void) didEndDrawing:(ICPaintView*)sender;
@end

@class ICPaintCommand;
@protocol ICPaintCommandBuilder <NSObject>
@required
- (ICPaintCommand*)buildCommand;
@end

@interface ICPaintView : UIView

@property (nonatomic) id<ICPaintViewDelegate> delegate;
@property (nonatomic) id<ICPaintCommandBuilder> commandBuilder;

- (UIImage*)textureImageForName:(NSString*)name;
- (BOOL) hasTextureImageForName:(NSString*)name;
- (void) addTextureImage:(UIImage*)image forName:(NSString*)name;
- (void)removeTextureImageforName:(NSString*)name;
- (void)setCurrentTexture:(NSString*)textureName;

- (void)clear;
- (void)setBrushSize:(CGFloat)size;
- (void)setBrushColor:(UIColor*)color;
- (UIImage*)getImage;



- (void)drawLineFromPoint:(CGPoint)start toPoint:(CGPoint)end;
- (void)drawTextureToRect:(CGRect)rect;
- (void)render;

- (void)undo;
- (void)redo;
- (BOOL)canUndo;
- (BOOL)canRedo;

- (void)useShader:(ICPaintViewShader)shader;

@end
