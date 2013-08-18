attribute vec4 position;
attribute vec2 texcoord;
uniform mat4 MVP;
varying vec2 texcoordVarying;

void main()
{
	gl_Position = MVP * position;
    texcoordVarying = texcoord;
}