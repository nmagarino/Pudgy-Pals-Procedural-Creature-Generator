import {vec2, vec3} from 'gl-matrix';

class Limb {
  jointPos: vec3[];
  jointRadii: number[];
  isLeg: boolean;

  constructor(isLeg: boolean) {
    this.isLeg = isLeg;
    this.jointPos = [];
    this.jointRadii = [];
    // if(isLeg) {
    //   console.log("LEggy");
    // }
    // else {
    //   // once arm, will stay arm
    //   console.log("Army");
    // }
    //console.log("hey");
  }

  generate(startPos: vec3, startRadius: number) {
    let numJoints = Math.floor(Math.random() * 3. + 2.);

    let radius = (Math.random() * 2 - 1) * 0.1 + startRadius;
    if (radius > 0.25) radius = 0.25;
    if (radius < 0.05) radius = 0.05;
    
    this.jointPos.push(startPos);
    this.jointRadii.push(radius);

    for (let i = 1; i < numJoints; i++) {
      let yaw = (Math.random()) * Math.PI * 0.8 + Math.PI;
      let pitch = (Math.random() * 2 - 1) * Math.PI * 0.35;
      if (!this.isLeg) pitch -= 0.5;
      let r = this.jointRadii[i-1]/0.2 * (Math.random() * 0.5 + 0.2 + this.jointRadii[i-1]/2);

      let dx = r * Math.sin(pitch) * Math.cos(yaw);
      let dy = r * Math.cos(pitch);
      let dz = r * Math.sin(pitch) * Math.sin(yaw);
      let newPos = vec3.add(vec3.create(), this.jointPos[i-1], vec3.fromValues(dx, dy, dz));
      if (this.isLeg && i + 1 >= numJoints) {
        newPos[1] = 0.0;
      }
      if (newPos[2] < 0.05) newPos[2] = 0.1;
      if (newPos[1] > -0.1) newPos[1] = -0.1;
      this.jointPos.push(newPos);
      radius += (Math.random() * 2 - 1) * 0.05 - 0.1;
      if (radius > 0.25) radius = 0.25;
      if (radius < 0.05) radius = 0.05;
      this.jointRadii.push(radius);
    }
  }

  animate(time: number) {
    
  }
};

export default Limb;