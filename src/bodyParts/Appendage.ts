import {vec2, vec3} from 'gl-matrix';

class Appendages{

    appendageData: number[]; // In order, num appendages and positions of each

  constructor() {
  }

  generate(jointsPerLimb: number[], jointPos: number[]) {
      this.appendageData = [];


      this.appendageData.push(jointsPerLimb.length);

      let start: number = 0;
      let first: number = 0;
      for(let i : number = 0; i < jointsPerLimb.length; i++) {
          //need last position
          first = start + (3 * ((jointsPerLimb[i] - 1)));
          //console.log("first: " + first);
          this.appendageData.push(jointPos[first]);
          this.appendageData.push(jointPos[first + 1]);
          this.appendageData.push(jointPos[first + 2]);

          start = first + 3;

      }
      
  }


  animate(time: number) {
    // this.headData[1] += 0.01* Math.sin(time * 0.5 + 0.3 * 1);
  }
};

export default Appendages;