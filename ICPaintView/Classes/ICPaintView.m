//
//  ICPaintView.m
//  Pods
//
//  Created by Ichito Nagata on 2013/08/17.
//
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

#import "ICPaintView.h"
#import "shaderUtil.h"
#import "fileUtil.h"
#import "debug.h"

#import "ICPaintCommand.h"

//CONSTANTS:

#define kBrushPixelStep		3

// Shaders
enum {
    PROGRAM_POINT,
    PROGRAM_IMAGE,
    NUM_PROGRAMS
};

enum {
	UNIFORM_MVP,
    UNIFORM_POINT_SIZE,
    UNIFORM_VERTEX_COLOR,
    UNIFORM_TEXTURE,
	NUM_UNIFORMS
};

enum {
	ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
	NUM_ATTRIBS
};

typedef struct {
	char *vert, *frag;
	GLint uniform[NUM_UNIFORMS];
	GLuint id;
} programInfo_t;

programInfo_t program[NUM_PROGRAMS] = {
    { "point.vsh",   "point.fsh" },     // PROGRAM_POINT
    { "image.vsh",   "image.fsh" },     // PROGRAM_IMAGE
};

@interface ICPaintView ()
{
	// The pixel dimensions of the backbuffer
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	// OpenGL names for the renderbuffer and framebuffers used to render to this view
	GLuint viewRenderbuffer, viewFramebuffer;
    
    // OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
    GLuint depthRenderbuffer;
	
	textureInfo_t currentTexture;
    NSString *currentTextureName;
    
    CGFloat brushColor[4];          // brush color
    
	Boolean needsErase;
    
    // Shader objects
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint shaderProgram;
    
    // Buffer Objects
    GLuint vboId;
    
    BOOL initialized;
    
    ICPaintCommand *_currentCommand;
    NSMutableArray *_undoStack;
    NSMutableArray *_redoStack;

    NSMutableDictionary *_textureImages;
}

@end

@implementation ICPaintView

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {
	
    if ((self = [super initWithCoder:coder])) {
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = NO;
		// In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
			return nil;
		}
        
        // Set the view's scale factor as you wish
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
		// Make sure to start with a cleared buffer
		needsErase = YES;
        
        _undoStack = [NSMutableArray new];
        _redoStack = [NSMutableArray new];
        
        _textureImages = [NSMutableDictionary new];
	}
	
	return self;
}

-(void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
    
    if (!initialized) {
        initialized = [self initGL];
    }
    else {
        [self resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
	
	// Clear the framebuffer the first time it is allocated
	if (needsErase) {
		[self clear];
        [self render];
		needsErase = NO;
	}
}

- (void)setupShaders
{
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
	for (int i = 0; i < NUM_PROGRAMS; i++)
	{
		char *vsrc = readFile(pathForResource(program[i].vert));
		char *fsrc = readFile(pathForResource(program[i].frag));
		GLsizei attribCt = 0;
		GLchar *attribUsed[NUM_ATTRIBS];
		GLint attrib[NUM_ATTRIBS];
		GLchar *attribName[NUM_ATTRIBS] = {
            "position",
            "texcoord",
		};
		const GLchar *uniformName[NUM_UNIFORMS] = {
			"MVP", "pointSize", "vertexColor", "texture",
		};
		
		// auto-assign known attribs
		for (int j = 0; j < NUM_ATTRIBS; j++)
		{
			if (strstr(vsrc, attribName[j]))
			{
				attrib[attribCt] = j;
				attribUsed[attribCt++] = attribName[j];
			}
		}
		
		glueCreateProgram(vsrc, fsrc,
                          attribCt, (const GLchar **)&attribUsed[0], attrib,
                          NUM_UNIFORMS, &uniformName[0], program[i].uniform,
                          &program[i].id);
		free(vsrc);
		free(fsrc);
        
        
        glUseProgram(program[i].id);
        glUniformMatrix4fv(program[i].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
	}
    
    glError();
}

- (BOOL)initGL
{
    // Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffers(1, &viewFramebuffer);
	glGenRenderbuffers(1, &viewRenderbuffer);
	
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		return NO;
	}
    
    glViewport(0, 0, backingWidth, backingHeight);
    
    glGenBuffers(1, &vboId);
    [self setupShaders];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    return YES;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
	// Allocate color buffer backing based on the current layer size
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    // Update projection matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    for (int i = 0; i < NUM_PROGRAMS; i++) {
        glUseProgram(program[i].id);
        glUniformMatrix4fv(program[i].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    }
    
    
    // Update viewport
    glViewport(0, 0, backingWidth, backingHeight);
	
    return YES;
}

// Releases resources when they are not longer needed.
- (void)dealloc
{
    // Destroy framebuffers and renderbuffers
	if (viewFramebuffer) {
        glDeleteFramebuffers(1, &viewFramebuffer);
        viewFramebuffer = 0;
    }
    if (viewRenderbuffer) {
        glDeleteRenderbuffers(1, &viewRenderbuffer);
        viewRenderbuffer = 0;
    }
	if (depthRenderbuffer)
	{
		glDeleteRenderbuffers(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
    
    [self deallocCurrentTexture];
    
    // vbo
    if (vboId) {
        glDeleteBuffers(1, &vboId);
        vboId = 0;
    }
    
    // tear down context
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
}

- (void)deallocCurrentTexture
{
    if (currentTexture.id) {
		glDeleteTextures(1, &currentTexture.id);
		currentTexture.id = 0;
	}
}

# pragma mark -
# pragma mark Texture management

- (UIImage*)textureImageForName:(NSString*)name
{
    return (UIImage*)[_textureImages objectForKey:name];
}
- (BOOL) hasTextureImageForName:(NSString*)name
{
    return [self textureImageForName:name] != nil;
}

- (void) addTextureImage:(UIImage*)image forName:(NSString*)name
{
    [_textureImages setObject:image forKey:name];
}

- (void)removeTextureImageforName:(NSString*)name
{
    [_textureImages removeObjectForKey:name];
}

- (void)setCurrentTexture:(NSString*)textureName
{
    if ([self hasTextureImageForName:textureName] && ! [textureName isEqualToString:currentTextureName]) {
        currentTexture = [self textureForName:textureName];
        currentTextureName = textureName;
    }
}

- (textureInfo_t)textureForName:(NSString*)textureName
{
    CGImageRef		imageRef;
	CGContextRef	imageContext;
	GLubyte			*imageData;
	size_t			width, height;
    GLuint          texId;
    textureInfo_t   texture;
    
    [self deallocCurrentTexture];
    
    UIImage *image = [self textureImageForName:textureName];
    
    imageRef = image.CGImage;
    
    width = CGImageGetWidth(imageRef);
    height = CGImageGetHeight(imageRef);
    
    if(imageRef) {
        imageData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
        
        imageContext = CGBitmapContextCreate(imageData, width, height, 8, width * 4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), imageRef);
        CGContextRelease(imageContext);
        
        GLint pixelFormat;
        GLenum type;
        CGImageAlphaInfo info = CGImageGetAlphaInfo(imageRef);
        BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) || (info == kCGImageAlphaPremultipliedFirst) || (info == kCGImageAlphaLast) || (info == kCGImageAlphaFirst) ? YES : NO);
        if(CGImageGetColorSpace(imageRef)) {
            if(hasAlpha) {
                pixelFormat = GL_RGBA;
                type = GL_UNSIGNED_BYTE;
            } else {
                pixelFormat = GL_RGB;
                type = GL_UNSIGNED_SHORT_5_6_5;
            }
        } else {
            pixelFormat = GL_ALPHA;
            type = GL_UNSIGNED_BYTE;
        }
        
        glGenTextures(1, &texId);
        glBindTexture(GL_TEXTURE_2D, texId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, pixelFormat, width, height, 0, pixelFormat, type, imageData);
        
        free(imageData);
        
        texture.id = texId;
        texture.width = width;
        texture.height = height;
    }
    
    return texture;
}



- (void)clear
{
	[EAGLContext setCurrentContext:context];
	
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);

}

- (void)render
{
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
}

# pragma mark -
# pragma mark Drawing

- (void)drawLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	static GLfloat*		vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger			vertexCount = 0;
	
	[EAGLContext setCurrentContext:context];
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	
	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
	
	if(vertexBuffer == NULL) {
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
    }
	
    CGFloat dx = (end.x - start.x);
    CGFloat dy = (end.y - start.y);
	int count = MAX(ceilf(sqrtf(dx * dx + dy * dy) / kBrushPixelStep), 1);
	for(int i = 0; i < count; ++i) {
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
    
	glBindBuffer(GL_ARRAY_BUFFER, vboId);
	glBufferData(GL_ARRAY_BUFFER, vertexCount * 2 * sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
	
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);

	glDrawArrays(GL_POINTS, 0, vertexCount);

    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)drawTextureToRect:(CGRect)rect
{
    GLfloat x = rect.origin.x;
    GLfloat y = rect.origin.y;
    GLfloat w = rect.size.width;
    GLfloat h = rect.size.height;
    
    y += h;
    h *= -1;
    
    CGFloat scale = self.contentScaleFactor;
	x *= scale;
	y *= scale;
	w *= scale;
	h *= scale;
    
    float vertexs[] = {
        x,      y,      //left top
        x,      y + h,  //left bottom
        x + w,  y,      //right top
        x + w,  y + h,  //right bottom
    };
    
    
    float texcoords[] = {
        0.0f, 0.0f, //left top
        0.0f, 1.0f, //left bottom
        1.0f, 0.0f, //right top
        1.0f, 1.0f, //right bottom
    };
     
    glUseProgram(program[PROGRAM_IMAGE].id);
    glUniform1i(program[PROGRAM_IMAGE].uniform[UNIFORM_TEXTURE], 0);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, false, 0, texcoords);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, false, 0, vertexs);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}



# pragma mark -
# pragma mark Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (! _currentCommand) {
        _currentCommand = [self.commandBuilder buildCommand];
        _currentCommand.paintView = self;
        [_currentCommand prepare];
        [_redoStack removeAllObjects];
    }
    
    CGPoint point = [self touchPointOfEvent:event];
    [_currentCommand didTouchesBeginAtPoint:point];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didBeginDrawing:)]) {
        [self.delegate didBeginDrawing:self];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [self touchPointOfEvent:event];
    [_currentCommand didTouchesMoveAtPoint:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [self touchPointOfEvent:event];
    [_currentCommand didTouchesEndAtPoint:point];
    [_undoStack addObject:_currentCommand];
    
    _currentCommand = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didEndDrawing:)]) {
        [self.delegate didEndDrawing:self];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If appropriate, add code necessary to save the state of the application.
	// This application is not saving state.
}

- (CGPoint)touchPointOfEvent:(UIEvent*)event
{
    UITouch *touch = [[event touchesForView:self] anyObject];
    CGPoint point = [touch locationInView:self];
    point.y = self.bounds.size.height - point.y;
    return point;
}

# pragma mark -
# pragma mark Brush

- (void)setBrushSize:(CGFloat)size
{
    glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], size);
}

- (void)setBrushColor:(UIColor*)color
{
    const int numComponents = CGColorGetNumberOfComponents(color.CGColor);
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    if (numComponents == 4) {
        CGFloat alpha = components[3];
        brushColor[0] = components[0] * alpha;
        brushColor[1] = components[1] * alpha;
        brushColor[2] = components[2] * alpha;
        brushColor[3] = alpha;
    } else {
        CGFloat alpha = components[1];
        brushColor[0] = components[0] * alpha;
        brushColor[1] = components[0] * alpha;
        brushColor[2] = components[0] * alpha;
        brushColor[3] = alpha;
    }
    
    if (initialized) {
        glUseProgram(program[PROGRAM_POINT].id);
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
    }
}

- (UIImage*)captureImage
{
	size_t w = [self frame].size.width * self.contentScaleFactor;
	size_t h = [self frame].size.height * self.contentScaleFactor;
	int pixelCount = 4 * w * h;
	GLubyte* data = malloc(pixelCount * sizeof(GLubyte));
	glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
	CGColorSpaceRef space =  CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(data, w, h, 8, w * 4, space, kCGImageAlphaPremultipliedLast);
	CGImageRef img = CGBitmapContextCreateImage(ctx);

	UIGraphicsBeginImageContext(CGSizeMake(w, h));
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
	CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), img);
	CGContextRotateCTM(contextRef, M_PI);
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();

	CGContextRelease(ctx);
    CGColorSpaceRelease(space);
	CGImageRelease(img);
	UIGraphicsEndImageContext();
    free(data);
	
    return result;
}

- (void)useShader:(ICPaintViewShader)shader
{
    glUseProgram(program[shader].id);
}

# pragma mark -
# pragma mark Undo and Redo

- (void) undo
{
    ICPaintCommand *lastCommand = _undoStack.lastObject;
    if (lastCommand == nil) {
        return;
    }
    [_undoStack removeLastObject];
    [_redoStack addObject:lastCommand];
    
    [self clear];
    for (ICPaintCommand *command in _undoStack) {
        [command prepare];
        [command execute];
    }
    [self render];
}

- (void) redo
{
    ICPaintCommand *lastCommand = _redoStack.lastObject;
    if (lastCommand == nil) {
        return;
    }
    [_redoStack removeLastObject];
    [_undoStack addObject:lastCommand];
    
    [lastCommand prepare];
    [lastCommand execute];
    [self render];
}

- (BOOL)canUndo
{
    return _undoStack.count > 0;
}

- (BOOL)canRedo
{
    return _redoStack.count > 0;
}



@end
