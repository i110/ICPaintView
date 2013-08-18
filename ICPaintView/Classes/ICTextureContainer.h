//
//  ICTextureContainer.h
//  ICPaintView
//
//  Created by Ichito Nagata on 2013/08/18.
//
//

#import <Foundation/Foundation.h>

#import "ICTexture.h"

// Texture
typedef struct {
    GLuint id;
    GLsizei width, height;
} textureInfo_t;

@interface ICTextureContainer : NSObject

@end
