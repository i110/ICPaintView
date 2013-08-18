//
//  ICTextureContainer.m
//  ICPaintView
//
//  Created by Ichito Nagata on 2013/08/18.
//
//

#import "ICTextureContainer.h"

@interface ICTextureContainer ()
{
    NSMutableDictionary *textures;
}
@end

@implementation ICTextureContainer

- (id)init
{
    self = [super init];
    if (self) {
        textures = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    for (NSString *textureName in textures.allKeys) {
        textureInfo_t *texture = [self getTexture:textureName];
        glDeleteTextures(1, &texture->id);
    }
}

- (textureInfo_t*)getTexture:(NSString*)name
{

    NSValue *value = (NSValue *)[textures objectForKey:name];
    if (value == nil) {
        return NULL;
    }

    textureInfo_t *texture;
    if ((texture=(textureInfo_t*)malloc(sizeof(textureInfo_t))) == NULL) {
        return NULL;
    }
    [value getValue:&*texture];
    return texture;
}

- (BOOL)hasTextureWithName:(NSString*)name
{
    return [textures objectForKey:name] != nil;
}

- (void)addTextureWithName:(NSString*)name image:(UIImage*)image
{
    CGImageRef		imageRef = image.CGImage;
	GLubyte			*data;
    GLuint          texId;
    textureInfo_t   texture;
    
    size_t width  = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    if(imageRef) {
        data = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
        
        CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width * 4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(ctx, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), imageRef);
        CGContextRelease(ctx);
        
        
        glGenTextures(1, &texId);
        glActiveTexture(GL_TEXTURE0 + textures.count);
        glBindTexture(GL_TEXTURE_2D, texId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        free(data);
        
        texture.id = texId;
        texture.width = width;
        texture.height = height;
    }
    NSValue *value = [NSValue value:&texture withObjCType:@encode(textureInfo_t)];
    [textures setObject:value forKey:name];
}

@end
