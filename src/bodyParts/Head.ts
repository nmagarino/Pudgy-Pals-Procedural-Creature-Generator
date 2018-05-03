import {vec2, vec3} from 'gl-matrix';

class Head {

    headData: number[]; // In order, contains head position (x,y,z), radius, then type

  constructor() {
  }

  generate(spinePos: number[], spineRadii: number[], type: number) {
    this.headData = [];

    let firstPos: number[] = [];
    firstPos.push(spinePos[0]);
    firstPos.push(spinePos[1]);
    firstPos.push(spinePos[2]);

    let firstRadii = spineRadii[0];

    //let headPos: number[] = [];

    // new head position is the first metaball position plus the radius to the left (for now)
    this.headData.push(firstPos[0] - firstRadii);
    this.headData.push(firstPos[1]);
    this.headData.push(firstPos[2]);

    // Find radius of head
    let sum: number = 0;
    let avg: number = 0;
    
    for(let i: number = 0; i < spineRadii.length; i++) {
        sum += spineRadii[i];
    }

    avg = sum / spineRadii.length;

    this.headData.push(avg);
    
    if(type == -1) {
    let rand :number = Math.random();
    if(rand < .33) {
        this.headData.push(0.0);
    }
    else if(.33 < rand && rand < .66) {
        this.headData.push(1.0);
    }
    else {
        this.headData.push(2.0);
    }
    }
    else {
        this.headData.push(type);
    }
  }


  animate(time: number) {
    // this.headData[1] += 0.01* Math.sin(time * 0.5 + 0.3 * 1);
  }
};

export default Head;