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

    for (let i = 0; i < numMetaBalls; i++) {
      this.metaBallRadii.push(0.3 * Math.random() + 0.1);
    }
    
    this.randomizeSpline();
    this.metaBallPos;
    for (let t = 0; t < 1; t += 1/numMetaBalls) {
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
      this.metaBallPos.push(pos[0]);
      this.metaBallPos.push(pos[1]);
      this.metaBallPos.push(pos[2]);
    }
  }

  randomizeSpline() {
    let numSplinePoints = 4;
    for (let i = 0; i < numSplinePoints; i++) {
      let newPoint = vec3.fromValues(0.8 * i + 0.3 * Math.random(), Math.random(), 0);
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