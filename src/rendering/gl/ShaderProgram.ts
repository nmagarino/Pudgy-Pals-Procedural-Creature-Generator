import {vec2, vec3, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;

  unifView: WebGLUniformLocation;

  unifResolution: WebGLUniformLocation;

  unifTime: WebGLUniformLocation;

  unifSpineLocations: WebGLUniformLocation;
  unifSpineRadii: WebGLUniformLocation;
  unifJointNumber: WebGLUniformLocation;
  unifLimbJointLocations: WebGLUniformLocation;
  unifLimbJointRadii: WebGLUniformLocation;
  unifLimbJointIDs: WebGLUniformLocation;
  unifHead: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    // Raymarcher only draws a quad in screen space! No other attributes
    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");

    // TODO: add other attributes here
    this.unifView   = gl.getUniformLocation(this.prog, "u_View");
    this.unifResolution = gl.getUniformLocation(this.prog, "u_Resolution");
    this.unifTime       = gl.getUniformLocation(this.prog, "u_Time");
    this.unifSpineLocations = gl.getUniformLocation(this.prog, "u_SpineLoc");
    this.unifSpineRadii = gl.getUniformLocation(this.prog, "u_SpineRad");
    this.unifHead = gl.getUniformLocation(this.prog, "u_Head");
    this.unifLimbJointIDs = gl.getUniformLocation(this.prog, "u_JointID");
    this.unifLimbJointLocations = gl.getUniformLocation(this.prog, "u_JointLoc");
    this.unifLimbJointRadii = gl.getUniformLocation(this.prog, "u_JointRad");
    this.unifJointNumber = gl.getUniformLocation(this.prog, "u_jointNum");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setResolution(resolution: vec2) {
    this.use();
    if (this.unifResolution !== -1) {
      gl.uniform2fv(this.unifResolution, resolution);
    }
  }

  setTime(t : number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, t);
    }
  }

  // These are all float arrays that contain creature information

  setSpineLocations(locations : number[]) {
    this.use();
    if(this.unifSpineLocations !== -1) {
      gl.uniform1fv(this.unifSpineLocations, locations);
    }
  }

  setSpineRadii(radii : number[]) {
    this.use();
    if(this.unifSpineRadii !== -1) {
      gl.uniform1fv(this.unifSpineRadii, radii);
    }
  }

  setHead(properties : number[]) {
    this.use();
    if(this.unifHead !== -1) {
      gl.uniform1fv(this.unifHead, properties);
    }
  }

  setJointLocations(locations : number[]) {
    this.use();
    if(this.unifLimbJointLocations !== -1) {
      gl.uniform1fv(this.unifLimbJointLocations, locations);
    }
  }

  setJointRadii(radii : number[]) {
    this.use();
    if(this.unifLimbJointRadii !== -1) {
      gl.uniform1fv(this.unifLimbJointRadii, radii);
    }
  }

  setJointIDs(radii : number[]) {
    this.use();
    if(this.unifLimbJointIDs !== -1) {
      gl.uniform1fv(this.unifLimbJointIDs, radii);
    }
  }

  setJointNumber(num : number) {
    this.use();
    if(this.unifJointNumber !== -1) {
      gl.uniform1i(this.unifJointNumber, num);
    }
  }

  // TODO: add functions to modify uniforms

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);

  }
};

export default ShaderProgram;
