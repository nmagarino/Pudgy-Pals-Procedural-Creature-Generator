import {vec2, vec3} from 'gl-matrix';

class Limb {
  jointPos: vec3[];
  jointRadii: number[];
  isLeg: boolean;

  constructor(isLeg: boolean) {
    this.isLeg = isLeg;
    this.jointPos = [];
    this.jointRadii = [];
  }

  generate(startPos: vec3, startRadius: number) {
    let numJoints = Math.floor(Math.random() * 3. + 2.);

    let radius = (Math.random() * 2 - 1) * 0.1 + startRadius;
    if (radius > 0.4) radius = 0.4;
    if (radius < 0.1) radius = 0.1;
    
    this.jointPos.push(startPos);
    this.jointRadii.push(radius);

    for (let i = 1; i < numJoints; i++) {
      let yaw = (Math.random()) * Math.PI * 0.8;
      let pitch = (Math.random() * 2 - 1) * Math.PI * 0.35;
      let r = Math.random() * 0.5 + 0.2 + this.jointRadii[i-1]/2;

      let dx = r * Math.sin(pitch) * Math.cos(yaw);
      let dy = r * Math.cos(pitch);
      let dz = r * Math.sin(pitch) * Math.sin(yaw);
      let newPos = vec3.add(vec3.create(), this.jointPos[i-1], vec3.fromValues(dx, dy, dz));
      if (this.isLeg && i + 1 >= numJoints) {
        newPos[1] = 0;
      }
      this.jointPos.push(newPos);
      radius += (Math.random() * 2 - 1) * 0.15 - 0.1;
      if (radius > 0.4) radius = 0.4;
      if (radius < 0.1) radius = 0.1;
      this.jointRadii.push(radius);
    }
  }

  animate(time: number) {
    
  }
};

export default Limb;