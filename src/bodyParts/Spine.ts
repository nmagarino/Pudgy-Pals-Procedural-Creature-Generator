import {vec3} from 'gl-matrix';

class Spine {
  splinePoints: vec3[];
  metaBallPos: number[];
  metaBallRadii: number[];

  constructor() {
  }

  generate() {
    this.splinePoints = [];
    this.metaBallPos = [];
    this.metaBallRadii = [];

    let numMetaBalls = 12;

    let radius = (0.3 * Math.pow(Math.random(), 1.4) + 0.1);  //bias smaller radii
    for (let i = 0; i < numMetaBalls; i++) {
      this.metaBallRadii.push(radius);
      radius += 0.1 * (2 * Math.pow(Math.random(), 1.3) - 1); //bias shrinking over length
      if (radius < 0.1) radius = 0.1;
      if (radius > 0.4) radius = 0.4;
    }
    
    this.randomizeSpline();
    this.metaBallPos;
    let t = 0;
    for (let j = 0; j < numMetaBalls; j++) {
      let prevRadius = 0;
      if (j > 0) prevRadius = this.metaBallRadii[j-1];
      t += 1/numMetaBalls;
      let pos = this.getPosOnSpline(t);
      let posNearby = this.getPosOnSpline(t + 0.05);
      let normal = vec3.cross(vec3.create(), pos, posNearby);
      let facingUp = vec3.dot(normal, vec3.fromValues(0, 1, 0));
      if (pos[0] == 0 && pos[1] == 0 && pos[2] == 0) pos[0] += 0.01;
      this.metaBallPos.push(pos[0]);
      this.metaBallPos.push(pos[1]);
      this.metaBallPos.push(pos[2]);
    }
  }

  getPosOnSpline(t: number): vec3 {
    let qs: vec3[] = [];
    let rs: vec3[] = [];
    for (let i = 0; i < 3; i++) {
      let newPoint = vec3.create();
      vec3.subtract(newPoint, this.splinePoints[i + 1], this.splinePoints[i]);
      vec3.scale(newPoint, newPoint, t);
      vec3.add(newPoint, newPoint, this.splinePoints[i]);
      qs.push(newPoint);
    }
    for (let i = 0; i < 2; i++) {
      let newPoint = vec3.create();
      vec3.subtract(newPoint, qs[i + 1], qs[i]);
      vec3.scale(newPoint, newPoint, t);
      vec3.add(newPoint, newPoint, qs[i]);
      rs.push(newPoint);
    }
    let pos = vec3.create();
    vec3.subtract(pos, rs[1], rs[0]);
    vec3.scale(pos, pos, t);
    vec3.add(pos, pos, rs[0]);
    return pos;
  }

  randomizeSpline() {
    let numSplinePoints = 4;
    for (let i = 0; i < numSplinePoints; i++) {
      let newPoint = vec3.fromValues(0.6 * i + 0.3 * Math.random(), 1. * (2 * Math.random() - 1), 0);
      this.splinePoints.push(newPoint);
    }
  }

  animate(time: number) {
    for (let i = 1; i < this.metaBallPos.length; i += 3) {
      this.metaBallPos[i] += 0.01* Math.sin(time * 0.5 + 0.3 * i);
    }
  }
};

export default Spine;