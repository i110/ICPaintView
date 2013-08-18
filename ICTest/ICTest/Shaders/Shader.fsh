//
//  Shader.fsh
//  ICTest
//
//  Created by Ichito Nagata on 2013/08/17.
//  Copyright (c) 2013年 Ichito Nagata. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
