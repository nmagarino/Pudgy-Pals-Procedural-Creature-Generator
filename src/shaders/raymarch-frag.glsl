#version 300 es

precision highp float;

in vec4 fs_Pos;
out vec4 out_Col;

uniform vec2 u_Resolution;
uniform float u_Time;

uniform float u_SpineLoc[24];
uniform float u_SpineRad[8];

uniform float u_Head[5]; // indices 0-2 are positions, 3 is radius

float headType;

const int MAX_STEPS = 300;
const float MIN_DIST = 0.0001;
const float MAX_DIST = 100.0;
const float EPSILON = 0.002;



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

mat3 scaleMat(float amt) {
	return mat3(
		vec3(amt, 0.0, 0.0),
		vec3(0.0, amt, 0.0),
		vec3(0.0, 0.0, amt)
	);
}

// polynomial smooth min
float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sminExp( float a, float b, float k ) {
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

float sminPow( float a, float b, float k ) {
    a = pow( a, k ); b = pow( b, k );
    return pow( (a*b)/(a+b), 1.0/k );
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

 float sdCappedCylinder( vec3 p, vec2 h ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float udBox( vec3 p, vec3 b ) {
  return length(max(abs(p)-b,0.0));
}

float sdCone( vec3 p, vec2 c ) {
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

float sdCappedCone( in vec3 p, in vec3 c ) {
    vec2 q = vec2( length(p.xz), p.y );
    vec2 v = vec2( c.z*c.y/c.x, -c.z );
    vec2 w = v - q;
    vec2 vv = vec2( dot(v,v), v.x*v.x );
    vec2 qv = vec2( dot(v,w), v.x*w.x );
    vec2 d = max(qv,0.0)*qv/vv;
    return sqrt( dot(w,w) - max(d.x,d.y) ) * sign(max(q.y*v.x-q.x*v.y,w.y));
}

//~~~~~~~~~~~~~~~~~~~~~~~~~CODE FROM ROBOT CONSTRUCTION (SDF REFERENCE)~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
// float cubeSDF( vec3 p, float r) {
// 	vec3 d = abs(p) - vec3(r, r, r);   
//     float insideDistance = min(max(d.x, max(d.y, d.z)), 0.0);
//     float outsideDistance = length(max(d, 0.0));  
//     return insideDistance + outsideDistance;
// }

// h defines the width and height of the cylinder
// float sdCappedCylinder( vec3 p, vec2 h ) {
//   vec2 d = abs(vec2(length(p.xz),p.y)) - h;
//   return min(max(d.x,d.y),0.0) + length(max(d,0.0));
// }

// float udRoundBox( vec3 p, vec3 b, float r ) {
//   return length(max(abs(p)-b,0.0))-r;
// }

// float sdTorus(vec3 p, vec2 t) {
//   vec2 q = vec2(length(p.xz)-t.x,p.y);
//   return length(q)-t.y;
// }

// float headSDF(vec3 p) {
// 	float base = max(sphereSDF(p + vec3(0.0,-.6,0.0), .5), -cubeSDF(p, .6));
// 	float eyes = min(sphereSDF(p + vec3(0.25,-0.75,-.33), .1), sphereSDF(p + vec3(-0.25,-0.75,-.33), .1));
// 	float antennaes = min(sdCappedCylinder(p + vec3(.4,-1.0,0.2), vec2(.028,.4)), sdCappedCylinder(p + vec3(-.4,-1.0,0.2), vec2(.028,.4)));
// 	return min(min(base, eyes), antennaes);
// }

// float neckSDF(vec3 p) {
//     float outside = min(min(sdCappedCylinder(p + vec3(0.0,0.0,0.0), vec2(.1, .1)), sdCappedCylinder(p + vec3(0.0,-0.23,0.0), vec2(.1, .1))), 
// 		            sdCappedCylinder(p + vec3(0.0,-0.46,0.0), vec2(.1, .1)));
// 	float inner = sdCappedCylinder(p + vec3(0.0,-.5,0.0), vec2(.05, .4));
// 	return min(inner, outside);
// }

// float bodySDF(vec3 p) {
// 	float chest = udRoundBox(p + vec3(0.0, .3, 0.0), vec3(0.27,0.22,0.2), .07);
// 	float spine = sdCappedCylinder(p + vec3(0.0,0.74,0.0), vec2(.15, .15));
// 	return min(spine, chest);
// }

// float pelvisSDF(vec3 p) {
// 	return udRoundBox(p + vec3(0.0, 1.1, 0.0), vec3(0.26,0.18,0.17), .07);;
// }

// float shouldersSDF(vec3 p) {
// 	return min(udRoundBox(p + vec3(0.3,0.0,0.0), vec3(.1,.1,.23), .095), udRoundBox(p + vec3(-0.3,0.0,0.0) , vec3(.1,.1,.23), .095));
// }

// float handsSDF(vec3 p) {
// 	float cutCube = cubeSDF(p + vec3(1.4,-2.42,0.0), .25);
// 	float cutCube2 = cubeSDF(p + vec3(-1.4,-2.42,0.0), .25);
// 	return min(max(-cutCube, sdTorus(p * rotateMatX(90.0) + vec3(1.4,0.0,-2.06), vec2(0.34,0.08))),
// 			   max(-cutCube2, sdTorus(p * rotateMatX(90.0) + vec3(-1.4,0.0,-2.06), vec2(0.34,0.08))));	
// }

// float armsSDF(vec3 p) {
// 	float biceps =  min(sdCappedCylinder(p * rotateMatZ(90.0) + vec3(0.0,0.6,0.0), vec2(.1,.9)), sdCappedCylinder(p * rotateMatZ(90.0) + vec3(0.0,-0.6,0.0), vec2(.1,.9)));
//     float forearms = min(sdCappedCylinder(p + vec3(1.4,-0.8,0.0), vec2(.1,.9)), sdCappedCylinder(p + vec3(-1.4,-0.8,0.0), vec2(.1,.9)));

// 	return min(handsSDF(p),smin(biceps, forearms, 10.0));
// }

// float legsSDF(vec3 p) {
// 	return min(sdCappedCylinder(p + vec3(.2,2.0,0.0), vec2(.1, .8)), sdCappedCylinder(p + vec3(-.2,2.0,0.0), vec2(.1, .8)));
// }

// float feetSDF(vec3 p) {
// 	float foot1 = udRoundBox(p * rotateMatY(45.0) + vec3(0.2,2.7,-0.33), vec3(0.14,0.05,0.3), 0.06);
// 	float foot2 = udRoundBox(p * rotateMatY(-45.0) + vec3(-0.2,2.7,-0.33), vec3(0.14,0.05,0.3), 0.06);
// 	return min(foot2, foot1);
// }

// float upperBodySDF(vec3 p) {
// 	float headBod = (min(min(headSDF(rotateMatY(u_Time * 3.6) * p + vec3(0.0,-.1 + sin(u_Time / 2.0)/5.0,0.0) ), neckSDF(p)), smin(bodySDF(p),shouldersSDF(p),10.0) ));
// 	float armsToo = armsSDF(p * rotateMatX(-u_Time * 2.1));
// 	return min(headBod, armsToo);
// }

// float legsFeet(vec3 p) {
// 	return min(legsSDF(p), feetSDF(p));
// }

// // Combines elements into one scene
// float wholebodySDF(vec3 p) {
// 	vec3 pEdit = p /.15; 
// 	float part1 =  upperBodySDF(pEdit * rotateMatY(sin(u_Time / 4.0) * 28.45));
// 	float part2 = legsFeet(pEdit * rotateMatX(sin(u_Time / 2.5) * 6.4));
// 	return min(min(part1, part2), pelvisSDF(pEdit)) * .15;
// }
//~~~~~~~~~~~~~~~~~~~~~~~~~CODE FROM ROBOT CONSTRUCTION (SDF REFERENCE)~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
float bugHeadSDF(vec3 p) {
	p = p * rotateMatY(-90.0);
	float base = sphereSDF(p, u_Head[3]);
 	float eyes = min(sphereSDF(p + u_Head[3] * vec3(0.55,-0.35,-.71), u_Head[3] * .2), sphereSDF(p + u_Head[3] * vec3(-0.55,-0.35,-.71), u_Head[3] * .2));
	float mandibleBase = sdCappedCylinder(p + u_Head[3] * vec3(0.0,0.001,-.9), u_Head[3] * vec2(1.2, 0.1));
	float mandibles = max(mandibleBase, -sphereSDF(p + u_Head[3] * vec3(0.0,0.0,-0.60), .7 * u_Head[3]));
	mandibles = max(mandibles, -sphereSDF(p + u_Head[3] * vec3(0.0,0.0,-1.70), .7 * u_Head[3]));
	float head = smin(min(base, eyes), mandibles, .05);
	return head;
}

float dinoHeadSDF(vec3 p) {
	p = p * rotateMatY(-90.0);
	float base = sphereSDF(p, u_Head[3]);
	float topJaw = sphereSDF(p + u_Head[3] * vec3(0.0,0.3,-1.4), u_Head[3] * 1.08);
	topJaw = max(topJaw, -cubeSDF(p + u_Head[3] * vec3(0.0,1.4,-1.4), u_Head[3] * 1.2));
	float bottomJaw = sphereSDF(p + u_Head[3] * vec3(0.0,0.6,-1.0), u_Head[3] * .7);
	bottomJaw = max(bottomJaw, -cubeSDF((p + u_Head[3] * vec3(0.0,-.4,-1.7)) * rotateMatX(45.0), u_Head[3] * 1.1));
	float combine = smin(base, topJaw, .04);
	combine = smin(combine, bottomJaw, .08);

	float eyes = min(sphereSDF(p + u_Head[3] * vec3(.9,0.0,0.0), u_Head[3] * .3), sphereSDF(p + u_Head[3] * vec3(-0.9,0.0,0.0), u_Head[3] * .3));
	combine = min(combine, eyes);
	float brows = min(udBox((p + u_Head[3] * vec3(.85,-0.35,0.0)) * rotateMatX(-20.0), u_Head[3] * vec3(.3,.2,.5)), udBox((p + u_Head[3] * vec3(-0.85,-0.35,0.0)) * rotateMatX(-20.0), u_Head[3] * vec3(.3,.2,.5)));
	combine = min(combine, brows);

	float teeth = sdCappedCone((p + u_Head[3] * vec3(0.4,0.7,-1.8)) * rotateMatX(180.0), u_Head[3] * vec3(3.0,1.0,1.0));
	teeth = min(teeth, sdCappedCone((p + u_Head[3] * vec3(-0.4,0.7,-1.8)) * rotateMatX(180.0), u_Head[3] * vec3(3.0,1.0,1.0)));
	teeth = min(teeth, sdCappedCone((p + u_Head[3] * vec3(-0.4,0.7,-1.3)) * rotateMatX(180.0), u_Head[3] * vec3(2.7,1.0,1.0)));
	teeth = min(teeth, sdCappedCone((p + u_Head[3] * vec3(0.4,0.7,-1.3)) * rotateMatX(180.0), u_Head[3] * vec3(2.7,1.0,1.0)));
	combine = min(combine, teeth);
	return combine;
}

float trollHeadSDF(vec3 p) {
	p = p * rotateMatY(-270.0);
	float base = sphereSDF(p, u_Head[3]);
	float bottomJaw = sphereSDF(p + u_Head[3] * vec3(0.0,0.3,.62), u_Head[3] * 1.08);
	bottomJaw = max(bottomJaw, -cubeSDF(p + u_Head[3] * vec3(0.0,-1.0,.45), u_Head[3] * 1.3));
	float combine = smin(base, bottomJaw, .04);
	float teeth = sdCappedCone(p + u_Head[3] * vec3(0.65,-0.7,1.1), u_Head[3] * vec3(4.0,1.0,1.0));
	teeth = min(teeth, sdCappedCone(p + u_Head[3] * vec3(-0.65,-0.7,1.1), u_Head[3] * vec3(4.0,1.0,1.0)));
	teeth = min(teeth, sdCappedCone(p + u_Head[3] * vec3(-0.25,-0.2,1.4), u_Head[3] * vec3(3.4,.5,.5)));
	teeth = min(teeth, sdCappedCone(p + u_Head[3] * vec3(0.25,-0.2,1.4), u_Head[3] * vec3(3.4,.5,.5)));
	combine = min(combine, teeth);
	float eyes = min(sphereSDF(p + u_Head[3] * vec3(.3,-0.5,0.7), u_Head[3] * .2), sphereSDF(p + u_Head[3] * vec3(-.3,-0.5,0.7), u_Head[3] * .2));
	float monobrow = udBox((p + u_Head[3] * vec3(0.0,-0.7,.65)) * rotateMatX(-20.0), u_Head[3] * vec3(.6,.2,.2));
	combine = min(min(combine, eyes), monobrow);
	return combine;
}

float spineSDF(vec3 p) {
	float spine = MAX_DIST;
	for (int i = 0; i < u_SpineLoc.length(); i += 3) {
		if (u_SpineLoc[i] == 0. && u_SpineLoc[i+1] == 0. && u_SpineLoc[i+2] == 0.) continue;
		vec3 pTemp = p + vec3(u_SpineLoc[i], u_SpineLoc[i+1], u_SpineLoc[i+2]);
		spine = smin(spine, sphereSDF(pTemp, u_SpineRad[i/3]), 0.06);
	}
	return spine;
}

// OVERALL SCENE SDF -- rotates about z-axis (turn-table style)
float sceneSDF(vec3 p) {
	p += vec3(-1., 0, 0);
	p = p * rotateMatY(u_Time) ; // rotates creature

	if(u_Head[4] == 0.0) {
		headType = bugHeadSDF(p + vec3(u_Head[0], u_Head[1], u_Head[2]));
	}	
	else if(u_Head[4] == 1.0){
		headType = dinoHeadSDF(p + vec3(u_Head[0], u_Head[1], u_Head[2]));
	}	
	else if(u_Head[4] == 2.0){
		headType = trollHeadSDF(p + vec3(u_Head[0], u_Head[1], u_Head[2]));
	}
	return smin(spineSDF(p), headType, 0.08);
}

//~~~~~~~~~~~~~~~~~~~~ACTUAL RAY MARCHING STUFF~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
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

	// Colors geometry with Lambert Shader
	 vec3 p = eye + distance * dir;
	 vec3 lightVec = vec3(17.0,40.0,50.0) - p;
	 float diffuseTerm = dot(normalize(normal(p)), normalize(lightVec));
	 diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
	 float ambientTerm = 0.2;
	 float lightIntensity = diffuseTerm + ambientTerm;

	 out_Col = vec4(vec3(1.0,0.0,0.0) * lightIntensity, 1.0) ;
}
