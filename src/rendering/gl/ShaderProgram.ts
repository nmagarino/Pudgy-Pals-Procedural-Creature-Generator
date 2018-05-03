import {vec2, vec3, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';
import Texture from './Texture';

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
  unifLimbJointLocations: WebGLUniformLocation;
  unifLimbJointRadii: WebGLUniformLocation;
  unifLimbLengths: WebGLUniformLocation;
  unifHead: WebGLUniformLocation;
  unifBodyColor1: WebGLUniformLocation;
  unifBodyColor2: WebGLUniformLocation;
  unifBodyColor3: WebGLUniformLocation;
  unifBodyColor4: WebGLUniformLocation;

  unifTestMat: WebGLUniformLocation;
  unifRotations: WebGLUniformLocation;
  unifAppenRots: WebGLUniformLocation;
  unifAppenRad: WebGLUniformLocation;

  unifAppenData: WebGLUniformLocation;
  unifAppenBools: WebGLUniformLocation;

  unifTexUnits: Map<string, WebGLUniformLocation>;

   

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
    // this.unifEye   = gl.getUniformLocation(this.prog, "u_Eye");
    // this.unifForward   = gl.getUniformLocation(this.prog, "u_Forward");
    // this.unifUp   = gl.getUniformLocation(this.prog, "u_Up");
    // this.unifRight   = gl.getUniformLocation(this.prog, "u_Right");

    this.unifResolution = gl.getUniformLocation(this.prog, "u_Resolution");
    this.unifTime       = gl.getUniformLocation(this.prog, "u_Time");
    this.unifSpineLocations = gl.getUniformLocation(this.prog, "u_SpineLoc");
    this.unifSpineRadii = gl.getUniformLocation(this.prog, "u_SpineRad");
    this.unifHead = gl.getUniformLocation(this.prog, "u_Head");
    this.unifLimbLengths = gl.getUniformLocation(this.prog, "u_LimbLengths");
    this.unifLimbJointLocations = gl.getUniformLocation(this.prog, "u_JointLoc");
    this.unifLimbJointRadii = gl.getUniformLocation(this.prog, "u_JointRad");
    this.unifBodyColor1 = gl.getUniformLocation(this.prog, "u_Color1");
    this.unifBodyColor2 = gl.getUniformLocation(this.prog, "u_Color2");
    this.unifBodyColor3 = gl.getUniformLocation(this.prog, "u_Color3");
    this.unifBodyColor4 = gl.getUniformLocation(this.prog, "u_Color4");

    this.unifTestMat = gl.getUniformLocation(this.prog, "u_TestMat");
    this.unifRotations = gl.getUniformLocation(this.prog, "u_Rotations");
    this.unifAppenRots = gl.getUniformLocation(this.prog, "u_AppenRots");
    this.unifAppenRad = gl.getUniformLocation(this.prog, "u_AppenRad")

    this.unifAppenData = gl.getUniformLocation(this.prog, "u_AppenData");
    this.unifAppenBools = gl.getUniformLocation(this.prog, "u_AppenBools")

    this.unifTexUnits = new Map<string, WebGLUniformLocation>();

    

  }

  setupTexUnits(handleNames: Array<string>) {
    for (let handle of handleNames) {
      var location = gl.getUniformLocation(this.prog, handle);
      if (location !== -1) {
        this.unifTexUnits.set(handle, location);
      } else {
        console.log("Could not find handle for texture named: \'" + handle + "\'!");
      }
    }
  }

  bindTexToUnit(handleName: string, tex: Texture, unit: number) {
    this.use();
    var location = this.unifTexUnits.get(handleName);
    if (location !== undefined) {
      gl.activeTexture(gl.TEXTURE0 + unit);
      tex.bindTex();
      gl.uniform1i(location, unit);
    } else {
      console.log("Texture with handle name: \'" + handleName + "\' was not found");
    }
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setViewMatrix(vp: mat4) {
    this.use();
    if (this.unifView !== -1) {
      gl.uniformMatrix4fv(this.unifView, false, vp);
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

  setLimbLengths(lengths : number[]) {
    this.use();
    if(this.unifLimbLengths !== -1) {
      gl.uniform1iv(this.unifLimbLengths, lengths);
    }
  }

  setColors(color1: vec3, color2: vec3, color3: vec3, color4: vec3) {
    this.use();
    if (this.unifBodyColor1 !== -1) {
      gl.uniform3fv(this.unifBodyColor1, color1);
    }
    if (this.unifBodyColor2 !== -1) {
      gl.uniform3fv(this.unifBodyColor2, color2);
    }
    if (this.unifBodyColor2 !== -1) {
      gl.uniform3fv(this.unifBodyColor3, color3);
    }
    if (this.unifBodyColor2 !== -1) {
      gl.uniform3fv(this.unifBodyColor4, color4);
    }
  }

  setTestMatrix(test: mat4) {
    this.use();
    if (this.unifTestMat !== -1) {
      gl.uniformMatrix4fv(this.unifTestMat, false, test);
    }
  }

  setRotations(rotations: mat4[]) {
    let numbers : number[] = [];
    for(let i : number = 0; i < rotations.length; i++) {
      let m4 : mat4 = rotations[i];
      numbers.push(m4[0]);
      numbers.push(m4[1]);
      numbers.push(m4[2]);
      numbers.push(m4[3]);
      numbers.push(m4[4]);
      numbers.push(m4[5]);
      numbers.push(m4[6]);
      numbers.push(m4[7]);
      numbers.push(m4[8]);
      numbers.push(m4[9]);
      numbers.push(m4[10]);
      numbers.push(m4[11]);
      numbers.push(m4[12]);
      numbers.push(m4[13]);
      numbers.push(m4[14]);
      numbers.push(m4[15]);
    }
    this.use();
    if (this.unifRotations !== -1) {
      gl.uniformMatrix4fv(this.unifRotations, false, numbers);
    }
  }

  setAppenRotations(rotations: mat4[]) {
    let numbers : number[] = [];
    for(let i : number = 0; i < rotations.length; i++) {
      let m4 : mat4 = rotations[i];
      numbers.push(m4[0]);
      numbers.push(m4[1]);
      numbers.push(m4[2]);
      numbers.push(m4[3]);
      numbers.push(m4[4]);
      numbers.push(m4[5]);
      numbers.push(m4[6]);
      numbers.push(m4[7]);
      numbers.push(m4[8]);
      numbers.push(m4[9]);
      numbers.push(m4[10]);
      numbers.push(m4[11]);
      numbers.push(m4[12]);
      numbers.push(m4[13]);
      numbers.push(m4[14]);
      numbers.push(m4[15]);
    }
    this.use();
    if (this.unifRotations !== -1) {
      gl.uniformMatrix4fv(this.unifAppenRots, false, numbers);
    }
  }

  setAppenData(data : number[]) {
    this.use();
    if(this.unifAppenData !== -1) {
      gl.uniform1fv(this.unifAppenData, data);
    }
  }

  setAppenBools(data : number[]) {
    this.use();
    if(this.unifAppenBools !== -1) {
      gl.uniform1iv(this.unifAppenBools, data);
    }
  }

  setAppenRad(data : number[]) {
    this.use();
    if(this.unifAppenRad !== -1) {
      gl.uniform1fv(this.unifAppenRad, data);
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
