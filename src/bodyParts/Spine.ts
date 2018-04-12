import {vec3} from 'gl-matrix';

class Spine {
  splinePoints: vec3[];
  metaBallPos: number[];
  metaBallSize: number[];

  constructor() {
    
  }

  generate() {
    this.randomizeSpline;
    let numMetaBalls = 10;
    this.metaBallPos = [
      0., 0.1 * Math.sin(0.2 + 0.5), 0.,
      0.3, 0.1 * Math.sin(0.2 + 1), 0.,
      0.6, 0.1 * Math.sin(0.2 + 1.5), 0.,
      0.9, 0.1 * Math.sin(0.2 + 2), 0.
    ]
  }

  randomizeSpline() {
    let numSplinePoints = 4;
    for (let i = 0; i < numSplinePoints; i++) {
      let newPoint = vec3.fromValues(0, 0, 1 * i);
      this.splinePoints.push(newPoint);
    }
  }
};

export default Spine;