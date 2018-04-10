#version 300 es

precision highp float;

in vec4 fs_Pos;
out vec4 out_Col;

uniform vec2 u_Resolution;
uniform float u_Time;

const int MAX_STEPS = 300;
const float MIN_DIST = 0.0001;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

mat3 rotateMatX(float angle) {
	float rad = radians(angle);
	return mat3(
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, cos(rad), -sin(rad)),
		vec3(0.0, sin(rad), cos(rad))
	);
}

mat3 rotateMatY(float angle) {
	float rad = radians(angle);
	return mat3(
		vec3(cos(rad), 0.0, sin(rad)),
		vec3(0.0, 1.0, 0.0),
		vec3(-sin(rad), 0.0, cos(rad))
	);
}

mat3 rotateMatZ(float angle) {
	float rad = radians(angle);
	return mat3(
		vec3(cos(rad), -sin(rad), 0.0),
		vec3(sin(rad), cos(rad), 0.0),
		vec3(0.0, 0.0, 1.0)
	);
}

float smin( float a, float b, float k ) {
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

float sphereSDF(vec3 p, float r) {
		return length(p) - r;
}

float cubeSDF( vec3 p, float r) {
	vec3 d = abs(p) - vec3(r, r, r);   
    float insideDistance = min(max(d.x, max(d.y, d.z)), 0.0);
    float outsideDistance = length(max(d, 0.0));  
    return insideDistance + outsideDistance;
}

// h defines the width and height of the cylinder
float sdCappedCylinder( vec3 p, vec2 h ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float udRoundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.0))-r;
}

float sdTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float headSDF(vec3 p) {
	float base = max(sphereSDF(p + vec3(0.0,-.6,0.0), .5), -cubeSDF(p, .6));
	float eyes = min(sphereSDF(p + vec3(0.25,-0.75,-.33), .1), sphereSDF(p + vec3(-0.25,-0.75,-.33), .1));
	float antennaes = min(sdCappedCylinder(p + vec3(.4,-1.0,0.2), vec2(.028,.4)), sdCappedCylinder(p + vec3(-.4,-1.0,0.2), vec2(.028,.4)));
	return min(min(base, eyes), antennaes);
}

float neckSDF(vec3 p) {
    float outside = min(min(sdCappedCylinder(p + vec3(0.0,0.0,0.0), vec2(.1, .1)), sdCappedCylinder(p + vec3(0.0,-0.23,0.0), vec2(.1, .1))), 
		            sdCappedCylinder(p + vec3(0.0,-0.46,0.0), vec2(.1, .1)));
	float inner = sdCappedCylinder(p + vec3(0.0,-.5,0.0), vec2(.05, .4));
	return min(inner, outside);
}

float bodySDF(vec3 p) {
	float chest = udRoundBox(p + vec3(0.0, .3, 0.0), vec3(0.27,0.22,0.2), .07);
	float spine = sdCappedCylinder(p + vec3(0.0,0.74,0.0), vec2(.15, .15));
	return min(spine, chest);
}

float pelvisSDF(vec3 p) {
	return udRoundBox(p + vec3(0.0, 1.1, 0.0), vec3(0.26,0.18,0.17), .07);;
}

float shouldersSDF(vec3 p) {
	return min(udRoundBox(p + vec3(0.3,0.0,0.0), vec3(.1,.1,.23), .095), udRoundBox(p + vec3(-0.3,0.0,0.0) , vec3(.1,.1,.23), .095));
}

float handsSDF(vec3 p) {
	float cutCube = cubeSDF(p + vec3(1.4,-2.42,0.0), .25);
	float cutCube2 = cubeSDF(p + vec3(-1.4,-2.42,0.0), .25);
	return min(max(-cutCube, sdTorus(p * rotateMatX(90.0) + vec3(1.4,0.0,-2.06), vec2(0.34,0.08))),
			   max(-cutCube2, sdTorus(p * rotateMatX(90.0) + vec3(-1.4,0.0,-2.06), vec2(0.34,0.08))));	
}

float armsSDF(vec3 p) {
	float biceps =  min(sdCappedCylinder(p * rotateMatZ(90.0) + vec3(0.0,0.6,0.0), vec2(.1,.9)), sdCappedCylinder(p * rotateMatZ(90.0) + vec3(0.0,-0.6,0.0), vec2(.1,.9)));
    float forearms = min(sdCappedCylinder(p + vec3(1.4,-0.8,0.0), vec2(.1,.9)), sdCappedCylinder(p + vec3(-1.4,-0.8,0.0), vec2(.1,.9)));

	return min(handsSDF(p),smin(biceps, forearms, 10.0));
}

float legsSDF(vec3 p) {
	return min(sdCappedCylinder(p + vec3(.2,2.0,0.0), vec2(.1, .8)), sdCappedCylinder(p + vec3(-.2,2.0,0.0), vec2(.1, .8)));
}

float feetSDF(vec3 p) {
	float foot1 = udRoundBox(p * rotateMatY(45.0) + vec3(0.2,2.7,-0.33), vec3(0.14,0.05,0.3), 0.06);
	float foot2 = udRoundBox(p * rotateMatY(-45.0) + vec3(-0.2,2.7,-0.33), vec3(0.14,0.05,0.3), 0.06);
	return min(foot2, foot1);
}

float upperBodySDF(vec3 p) {
	float headBod = (min(min(headSDF(rotateMatY(u_Time * 3.6) * p + vec3(0.0,-.1 + sin(u_Time / 2.0)/5.0,0.0) ), neckSDF(p)), smin(bodySDF(p),shouldersSDF(p),10.0) ));
	float armsToo = armsSDF(p * rotateMatX(-u_Time * 2.1));
	return min(headBod, armsToo);
}

float legsFeet(vec3 p) {
	return min(legsSDF(p), feetSDF(p));
}

// Combines elements into one scene
float wholebodySDF(vec3 p) {
	vec3 pEdit = p /.15; 
	float part1 =  upperBodySDF(pEdit * rotateMatY(sin(u_Time / 4.0) * 28.45));
	float part2 = legsFeet(pEdit * rotateMatX(sin(u_Time / 2.5) * 6.4));
	return min(min(part1, part2), pelvisSDF(pEdit)) * .15;
}

float sceneSDF(vec3 p) {
	vec3 c = vec3(1.01, 1.01, 0.0);
	vec3 q = mod(p,c)-0.5*c;
	return wholebodySDF(q);
}

float march(vec3 rayOrigin, vec3 direction) {
	float dist = MIN_DIST;
	for(int i = 0; i < MAX_STEPS; i++) {
		vec3 pos = rayOrigin + dist * direction;
		float dt = sceneSDF(pos);
		if(dt < EPSILON) {
			return dist;
		}
		dist += dt;
		if(dist >= MAX_DIST) {
			return MAX_DIST;
		}
	}
	return MAX_DIST;
}

vec3 normal(vec3 p) {
	float gradX = sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z));
	float gradY = sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z));
	float gradZ = sceneSDF(vec3(p.x, p.y, p.z + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON));
	return normalize(vec3(gradX, gradY, gradZ));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}



void main() {
	
	vec4 pos = vec4(fs_Pos.x * (u_Resolution.x / u_Resolution.y),
	                fs_Pos.y,0.0,0.0);

    vec3 eye = vec3(0.0, 0.24, 12.0);
	vec3 dir = normalize(pos.xyz - eye);
	dir = (viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0,1.0,0.0)) * vec4(dir, 0.0)).xyz;
	float distance = march(eye, dir);

	if(distance >= MAX_DIST - 2.0 * EPSILON) {
		// Colors background with a gradient!
		vec4 col1 = vec4(0.0,0.0,1.0,1.0);
		vec4 col2 = vec4(0.0,1.0,0.0,1.0);
		out_Col = vec4(col1 * (gl_FragCoord.y / u_Resolution.y)) + vec4(col2 * (2.4 - (gl_FragCoord.y / u_Resolution.y)));
		return;
	}

	// Colors geometry
	 vec3 p = eye + distance * dir;
	 vec3 lightVec = vec3(17.0,40.0,50.0) - p;
	 float diffuseTerm = dot(normalize(normal(p)), normalize(lightVec));
	 diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
	 float ambientTerm = 0.2;
	 float lightIntensity = diffuseTerm + ambientTerm;

	 if(dot(dir, normal(p)) < mix(45.0, 44.0, max(0.0, dot(normal(p), lightVec)))) {
		 out_Col = vec4( vec3(1.0,1.0,1.0) * vec3(0.0,0.0,0.0) ,1.0);
		 return;
	 }

	 if(1.0 * max(0.0, dot(normal(p), lightVec)) <= 60.8) {
		 out_Col = vec4( vec3(1.0,0.0,0.0) * vec3(1.0,1.0,1.0), 1.0);
		 return;
	 }
}
