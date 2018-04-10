#version 300 es

precision highp float;

in vec4 vs_Pos;
out vec4 fs_Pos;

void main() {
	// TODO: Pass relevant info to fragment
	fs_Pos = vs_Pos;
	gl_Position = vs_Pos;
}
