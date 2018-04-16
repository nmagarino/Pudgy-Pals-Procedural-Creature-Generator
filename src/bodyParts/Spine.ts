import {vec2, vec3} from 'gl-matrix';

class Spine {
  splinePoints: vec3[];
  metaBallPos: number[];
  metaBallRadii: number[];

  maxSpineRadius = 0.4;
  minSpineRadius = 0.1;

  constructor() {
  }

  generate() {
    this.splinePoints = [];
    this.metaBallPos = [];
    this.metaBallRadii = [];

    let numMetaBalls = 12;

    let radius = ((this.maxSpineRadius - this.minSpineRadius) * Math.pow(Math.random(), 1.2) + this.minSpineRadius);  //pow to bias smaller radii
    for (let i = 0; i < numMetaBalls; i++) {
      this.metaBallRadii.push(radius);
      radius += 0.1 * (2 * Math.pow(Math.random(), 1.2) - 1); //pow to bias shrinking over length
      if (radius < this.minSpineRadius) radius = this.minSpineRadius;
      if (radius > this.maxSpineRadius) radius = this.maxSpineRadius;
    }
    
    this.randomizeSpline();
    this.metaBallPos;
    let t = 0;
    for (let j = 0; j < numMetaBalls; j++) {
      let radius = this.metaBallRadii[j]/0.4;
      let prevRadius = 0;
      if (j > 0) prevRadius = this.metaBallRadii[j-1];
      t += 1/numMetaBalls;
      let pos = this.getPosOnSpline(t);
      let posNearby = this.getPosOnSpline(t + 0.05);
      let slope = vec3.create();
      vec3.scale(slope, vec3.normalize(slope, vec3.subtract(slope, pos, posNearby)), -1 * this.metaBallRadii[j]);
      pos[0] += slope[1];
      pos[1] += slope[0];

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
      let newPoint = vec3.fromValues(0.8 * i + 0.3 * Math.random(), 1. * (2 * Math.random() - 1), 0);
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