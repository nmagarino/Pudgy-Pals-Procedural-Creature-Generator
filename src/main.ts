import { vec3, vec2, quat, mat4 } from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Square from './geometry/Square';
import Camera from './Camera';
import { setGL } from './globals';
import ShaderProgram, { Shader } from './rendering/gl/ShaderProgram';
import Creature from './bodyParts/Creature';
import Texture from './rendering/gl/Texture';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.

let screenQuad: Square;
let time: number = 0;
let creature: Creature = new Creature();
let textures: Texture[];

let raymarchShader: ShaderProgram;

const controls = {
  'Generate': generate
};

function generate() {
  raymarchShader.setSpineLocations([]);
  raymarchShader.setSpineRadii([]);
  raymarchShader.setHead([]);
  raymarchShader.setAppenData([]);
  raymarchShader.setJointLocations([]);
  raymarchShader.setLimbLengths([]);
  raymarchShader.setJointRadii([]);
  raymarchShader.setRotations([]);
  creature = new Creature();
  creature.generate(textures.length);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // TODO: add any controls you need to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'Generate');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement>document.getElementById('canvas');

  function setSize(width: number, height: number) {
    canvas.width = width;
    canvas.height = height;
  }

  const gl = <WebGL2RenderingContext>canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  //Load Textures
  textures = [];
  textures.push(new Texture('/resources/textures/noise.bmp'));
  textures.push(new Texture('/resources/textures/fleshy.bmp'));
  textures.push(new Texture('/resources/textures/furry.bmp'));
  textures.push(new Texture('/resources/textures/scaly1.bmp'));
  textures.push(new Texture('/resources/textures/scaly2.bmp'));
  textures.push(new Texture('/resources/textures/veiny.bmp'));

  screenQuad = new Square(vec3.fromValues(0, 0, 0));
  screenQuad.create();

  const camera = new Camera(vec3.fromValues(0, 1, 2.01), vec3.fromValues(0, 1, 2));
  camera.controls.translateSpeed = 0;
  camera.controls.zoomSpeed = 0;

  gl.clearColor(0.0, 0.0, 0.0, 1);
  gl.disable(gl.DEPTH_TEST);

  raymarchShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/screenspace-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/raymarch-frag.glsl')),
  ]);

  raymarchShader.setupTexUnits(["tex_Color1"]);
  raymarchShader.setupTexUnits(["tex_Color2"]);

  creature.generate(textures.length); // Pass in parameters for whole creature in GUI
  // pass in arms vs. legs data
  let appenBools: Array<number> = []; // 0 will be foot, 1 will be hand
    let armsNow: boolean = false;
    for (let i: number = 0; i < creature.limbs.length; i++) {
      if (armsNow) {
        appenBools.push(1);
        console.log("hand");
        continue;
      }
      if (creature.limbs[i].isLeg) {
        appenBools.push(0);
        console.log("foot");
      }
      else {
        armsNow = true;
        appenBools.push(1);
        console.log("hand");
      }
    }
    console.log(appenBools);
    raymarchShader.setAppenBools(appenBools);


  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();

    raymarchShader.bindTexToUnit("tex_Color1", textures[creature.texture1], 0);
    raymarchShader.bindTexToUnit("tex_Color2", textures[creature.texture2], 1);

    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    // TODO: get / calculate relevant uniforms to send to shader here
    // TODO: send uniforms to shader

    creature.animate(time);

    raymarchShader.setSpineLocations(creature.spineLocations);
    raymarchShader.setSpineRadii(creature.spine.metaBallRadii);
    raymarchShader.setHead(creature.head.headData);
    raymarchShader.setAppenData(creature.appendages.appendageData);




    let locations: Array<number> = creature.jointLocations;
    raymarchShader.setJointLocations(locations);

    let numJointsEach: Array<number> = creature.limbLengths;
    raymarchShader.setLimbLengths(numJointsEach);

    let radiis: Array<number> = creature.jointRadii;
    raymarchShader.setJointRadii(radiis);

    raymarchShader.setColors(
      creature.color1,
      creature.color2,
      creature.color3,
      creature.color4
    );



    

    creature.appendages.generate(numJointsEach, locations);
    //raymarchShader.setAppenBools(appenBools);
    //console.log(creature.appendages.appendageData);

    //raymarchShader.setJointNumber(7);

    let rotations: mat4[] = [];
    let finalRots: mat4[] = [];
    let finalRadii: number[] = [];
    let start: number = 0;
    //need to do separately for each limb
    for (let k: number = 0; k < numJointsEach.length; k++) {
      //for as many joints in each limb
      for (let l: number = 0; l < numJointsEach[k] - 1; l++) {

        let a: vec3 = vec3.fromValues(0.0, 1.0, 0.0);
        let b: vec3 = vec3.create();
        let point0: vec3 = vec3.fromValues(locations[start], locations[start + 1], locations[start + 2]);
        let point1: vec3 = vec3.fromValues(locations[start + 3], locations[start + 4], locations[start + 5]);
         
        b = vec3.subtract(b, point1, point0);
        b = vec3.normalize(b, b);
        let q: quat;
        q = quat.create();
        q = quat.rotationTo(q, a, b);
        let m4: mat4 = mat4.create();
        m4 = mat4.fromQuat(m4, q);
        rotations.push(m4);
        if(l == numJointsEach[k] - 2) {
          //console.log(locations[start + 1]);
          finalRots.push(m4);
          finalRadii.push(radiis[start / 3]);
      
       }

        start = start + 3;

      }
      start = start + 3;

    }



    raymarchShader.setRotations(rotations);
    raymarchShader.setAppenRotations(finalRots);
    raymarchShader.setAppenRad(finalRadii);


    raymarchShader.setResolution(vec2.fromValues(window.innerWidth, window.innerHeight));
    raymarchShader.setTime(time);
    raymarchShader.setViewMatrix(camera.viewMatrix);

    // March!
    raymarchShader.draw(screenQuad);

    time = time + 1;

    // TODO: more shaders to layer / process the first one? (either via framebuffers or blending)

    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function () {
    setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
