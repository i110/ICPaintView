attribute vec4 position;

uniform mat4 MVP;
uniform float pointSize;
uniform lowp vec4 vertexColor;

varying lowp vec4 color;

void main()
{
	gl_Position = MVP * position;
    gl_PointSize = pointSize;
    color = vertexColor;
}
