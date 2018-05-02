#version 300 es

precision highp float;

in vec4 fs_Pos;
out vec4 out_Col;

uniform vec2 u_Resolution;
uniform float u_Time;
uniform mat4 u_View;

uniform float u_SpineLoc[24];
uniform float u_SpineRad[8];

uniform float u_Head[5]; // indices 0-2 are positions, 3 is radius
uniform float u_AppenData[50];
uniform int u_AppenBools[50];
uniform float u_AppenRad[50];

uniform int u_LimbLengths[8];  //size is number of limbs
uniform float u_JointLoc[90]; //size is number of joints * 3
uniform float u_JointRad[30]; //size is number of joints

uniform vec3 u_Color1;
uniform vec3 u_Color2;
uniform vec3 u_Color3;
uniform vec3 u_Color4;

uniform mat4[100] u_Rotations;
uniform mat4[50] u_AppenRots;

float headType;

const int MAX_STEPS = 300;
const float MIN_DIST = 0.0001;
const float MAX_DIST = 100.0;
const float EPSILON = 0.002;

uniform sampler2D tex_Color1;
uniform sampler2D tex_Color2;

vec3 eyePos;
float eyeSize;

// int numAppen = 0; // for appendages
// int armsNow = 0; // 0 for false, 1 for true

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

float udRoundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.0))-r;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

// a better capped cone function (like what)
float sdConeSection( in vec3 p, in float h, in float r1, in float r2 ) {
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5*(r1-r2)/h;
    float d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

//~~~~~HEAD SDFs~~~~~///
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

//~~~~HAND/FEET SDFs~~~~~//

// For now, size is based on head size, but later make it the average joint size
float clawFootSDF(vec3 p, float size) {
	size = size * 2.0;
	float base = udRoundBox(p, size * vec3(.6,.6,.3), .001);
	float fingees = sdConeSection((p + size * vec3(0.5,-0.9,0.3)) * rotateMatZ(-20.0), size * 1.0, size * .3, size * .05);
	fingees = min(fingees, sdConeSection((p + size * vec3(-0.5,-0.9,0.3)) * rotateMatZ(20.0), size * 1.0, size * .3, size * .05));
    fingees = min(fingees, sdConeSection(p + size * vec3(0.0,-1.1,0.3), size * 1.0, size * .3, size * .05));
	float combine = smin(base, fingees, .13); // final foot
	return combine;
}


float handSDF(vec3 p, float size) {
	//float size = u_Head[3] / 1.5;
	//size = 1.0;
	float base = udRoundBox(p, size * vec3(.6,.6,.2), .08);
	float fingee1 = sdConeSection((p + size * vec3(1.1,-0.7,0.0)) * rotateMatZ(-30.0), size * 1.0, size * .5, size * .2);
	float fingee2 = sdConeSection((p + size * vec3(0.45,-1.9,0.0)) * rotateMatZ(0.0), size * 1.0, size * .5, size * .2);
	float fingee3 = sdConeSection((p + size * vec3(-0.45,-1.9,0.0)) * rotateMatZ(0.0), size * 1.0, size * .5, size * .2);
	fingee1 = min(fingee1, fingee2);
	fingee1 = min(fingee1, fingee3);
	float combine = smin(base, fingee1, .09);
	return combine;
}

float appendagesSDF(vec3 p) {
	float all = MAX_DIST;
	float angle;
	//angle to slightly offset each foot
	float angle1 = -35.0;
	float angle2 = 35.0;

	int armsNow = 0;
	int numAppen = 0;

	for(int i = 0; i < int(u_AppenData[0]); i++) {
		int start = (i * 3) + 1;
		vec3 offset = vec3(u_AppenData[start], u_AppenData[start + 1], u_AppenData[start + 2]);

		if((i % 2) == 0) {
			angle = angle1;
		}
		else {
			angle = angle2;
		}
		float foot;

		if(u_AppenBools[numAppen] == 1) {
		armsNow = 1;
		}

		if(armsNow == 0) {
			foot = clawFootSDF((p + offset)*rotateMatZ(90.0) * rotateMatY(90.0) * rotateMatZ(angle), u_AppenRad[numAppen]);
		}
		else {
			vec3 q = (inverse(u_AppenRots[numAppen]) * vec4((p + offset),1.0)).xyz;
			foot = handSDF(q* rotateMatZ(180.0),u_AppenRad[numAppen]);
		}

		// //if(u_AppenBools[numAppen] != 0.0) {
		// if((numAppen % 2) == 0) {
		// 	foot = clawFootSDF((p + offset)*rotateMatZ(90.0) * rotateMatY(90.0) * rotateMatZ(angle));		
		// }
		// else {
		// 	foot = handSDF((p + offset) * rotateMatZ(135.0));
		// }
		// else if(u_AppenBools[2] == 0){			
		// 	
		// }

		numAppen = numAppen + 1;

		// if((p + offset).y == 100.0) { //should be 0, but does this work
		// 	foot = handSDF((p + offset) * rotateMatZ(135.0));
		// }
		// else {
		// 	foot = clawFootSDF((p + offset)*rotateMatZ(90.0) * rotateMatY(90.0) * rotateMatZ(angle));
		// }
		all = min(all, foot);
	}

	return all;
}

float armSDF(vec3 p) {

	int countSegs = 0;

	float allLimbs = MAX_DIST;
	int incr = 0;
	int numLimbs = 0;
	int jointNum = 0;
	for (int i = 0; i < u_LimbLengths.length(); i++) {
		jointNum += u_LimbLengths[i];
	}

	//this is for each limb
	for(int j = 0; j < (jointNum*3); j = j + incr) {
	numLimbs++;
		
	int count = 0;
	
	// NEED joint number to do the below operations...
	
	//count is number of joints in this limb
	count = int(u_LimbLengths[numLimbs - 1]);	

	float arm = MAX_DIST;
	// all joint positions for a LIM (jointNum * 3)
	for(int i = j; i < (j+(count * 3)); i = i + 3) {
		vec3 pTemp = p + vec3(u_JointLoc[i], u_JointLoc[i+1], u_JointLoc[i+2]);
		arm = min(arm, sphereSDF(pTemp, u_JointRad[i/3]));

	}

	// for 3 * (jointNum(per limb) - 1), each joint until last one
	float segments = MAX_DIST;
	
	for(int i = j; i < (j+((count-1) * 3)); i = i + 3) {
		vec3 point0 = vec3(u_JointLoc[i], u_JointLoc[i+1], u_JointLoc[i+2]);
	    vec3 point1 = vec3(u_JointLoc[i+3], u_JointLoc[i+4] ,u_JointLoc[i+5]);
		vec3 midpoint = vec3((point0.x + point1.x)/2.0, (point0.y + point1.y)/2.0, (point0.z + point1.z)/2.0);
		float len = distance(point0, point1);
		
		vec3 dir = point1 - point0; //dir is correct
		
		

		mat4 outMat4 = u_Rotations[countSegs];
		countSegs++;

		vec3 q = (inverse(outMat4) * vec4((p + midpoint),1.0)).xyz;



		float part = sdConeSection(q, len/2.0, u_JointRad[(i+3)/3],u_JointRad[i/3]);
		segments = min(segments, part);
	}

	float combine = smin(arm, segments, .2); // this is one arm
	allLimbs = min(allLimbs, combine); //merge with all other limbs

	incr = count * 3;

	} 

	return allLimbs;
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
	p += vec3(0, 0, 0);
	// p = p * rotateMatY(u_Time) ; // rotates creature

	if(u_Head[4] == 0.0) {
		headType = bugHeadSDF(p + vec3(u_Head[0], u_Head[1], u_Head[2]));
	}	
	else if(u_Head[4] == 1.0){
		headType = dinoHeadSDF(p + vec3(u_Head[0], u_Head[1], u_Head[2]));
	}	
	else if(u_Head[4] == 2.0){
		headType = trollHeadSDF(p + vec3(u_Head[0], u_Head[1], u_Head[2]));
	}
	float dist = smin(spineSDF(p), headType, .1);
	return smin(smin(armSDF(p), appendagesSDF(p), .2), dist, .1);
	
	//return min(handSDF(p+ vec3(-1.0,0.0,0.0), u_AppenRad[0]), clawFootSDF(p + vec3(1.0,0.0,0.0), u_AppenRad[0]));
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

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
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

vec3 triplanar(sampler2D tex, float scale, vec3 norm, vec3 pos) {
	vec3 xy = texture(tex, pos.xy * scale).rgb;
	vec3 xz = texture(tex, pos.xz * scale).rgb;
	vec3 yz = texture(tex, pos.yz * scale).rgb;
	return mix(mix(xz, yz, norm.x), xy, norm.z);
}

void main() {
	vec3 eye = -u_View[3].xyz;
	vec3 up = u_View[1].xyz;
	vec3 forward = u_View[2].xyz;
	vec3 right = u_View[0].xyz;

	vec2 coord = vec2(-fs_Pos.x * u_Resolution.x/u_Resolution.y, -fs_Pos.y);
	vec3 dest = eye + forward + right * coord[0] + up * coord[1];
	// vec3 viewDir = rayDirection(20.0, normalize(u_Resolution), coord);
    
    // mat4 viewToWorld = u_View;//viewMatrix(eye, vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0));
    
    vec3 dir = normalize(eye - dest); //(viewToWorld * vec4(viewDir, 0.0)).xyz;
	
	float distance = march(eye, dir);

	if(distance >= MAX_DIST - 2.0 * EPSILON) {
		// Colors background with a gradient!
		vec4 col1 = vec4(0.0,0.0,1.0,1.0);
		vec4 col2 = vec4(0.0,1.0,0.0,1.0);
		out_Col = vec4(col1 * (gl_FragCoord.y / u_Resolution.y)) + vec4(col2 * (2.4 - (gl_FragCoord.y / u_Resolution.y)));
		//out_Col = texture(tex_Color, gl_FragCoord.xy/u_Resolution);
		return;
	}

	// Colors geometry with Lambert Shader
	 vec3 p = eye + distance * dir;
	 vec3 norm = normalize(normal(p));
	 vec3 lightVec = vec3(17.0,40.0,50.0) - p;
	 float alpha = dot(norm, vec3(0, 1, 0));
	 if (alpha < 0.) alpha = 0.;
	 vec3 texture1 = triplanar(tex_Color1, 1., norm, p);
	 texture1 = mix(u_Color1, u_Color2, texture1.r);
	 vec3 texture2 = triplanar(tex_Color2, 1., norm, p);
	 texture2 = mix(u_Color3, u_Color4, texture2.r);
	 vec3 color = mix(texture1, texture2, alpha);
	 float diffuseTerm = dot(norm, normalize(lightVec));
	 diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
	 float ambientTerm = 0.2;
	 float lightIntensity = diffuseTerm + ambientTerm;

	 out_Col = vec4(color * lightIntensity, 1.0) ;

	//  out_Col = vec4(0.5 * (dir + vec3(1,1,1)), 1.);
}
