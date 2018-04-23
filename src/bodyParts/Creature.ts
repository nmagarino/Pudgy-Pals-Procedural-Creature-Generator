import Spine from './Spine';
import Head from './Head';
import Limb from './Limb';
import {vec2, vec3} from 'gl-matrix';

class Creature {
  spine: Spine;
  spineLocations: number[];
  head: Head;
  legs: Limb[];
  jointLocations: number[];
  jointRadii: number[];
  limbLengths: number[];

  constructor() {
  }

  generate() {
    this.spine = new Spine();
    this.spineLocations = [];
    this.head = new Head();
    this.legs = [];

    this.jointLocations = [];
    this.jointRadii = [];
    this.limbLengths = [];

    this.spine.generate();
    for (let i = 0; i < this.spine.metaBallPos.length; i++) {
      let spinePos = this.spine.metaBallPos[i];
      this.spineLocations.push(spinePos[0]);
      this.spineLocations.push(spinePos[1]);
      this.spineLocations.push(spinePos[2]);
    }

    // Head takes information from the spine that is made previously
    this.head.generate(this.spineLocations, this.spine.metaBallRadii);

    //Leg generation and parsing
    let numLegs = Math.pow(Math.random(), 2.4) * 4;
    for (let i = 0; i < numLegs; i++) {
      let leg1 = new Limb(true);
      let offset = Math.random() * this.spine.metaBallPos.length/numLegs;
      let spineIndex = Math.max(Math.min(Math.floor(i * this.spine.metaBallPos.length/numLegs + offset), this.spine.metaBallPos.length - 1), 0);
      let startPos = this.spine.metaBallPos[spineIndex];
      startPos[2] += this.spine.metaBallRadii[spineIndex]/2 + 0.1;
      leg1.generate(startPos, this.spine.metaBallRadii[spineIndex] * 0.7);

      let leg2 = new Limb(true);
      for (let j = 0; j < leg1.jointPos.length; j++) {
        leg2.jointPos.push(vec3.multiply(vec3.create(), leg1.jointPos[j], vec3.fromValues(1, 1, -1)));
        leg2.jointRadii.push(leg1.jointRadii[j]);
      }

      this.legs.push(leg1);
      this.legs.push(leg2);
    }

    for (let i = 0; i < this.legs.length; i++) {
      let leg = this.legs[i];
      this.limbLengths.push(leg.jointPos.length);
      for (let j = 0; j < leg.jointPos.length; j++) {
        let joint = leg.jointPos[j];
        this.jointLocations.push(joint[0]);
        this.jointLocations.push(joint[1]);
        this.jointLocations.push(joint[2]);
        this.jointRadii.push(leg.jointRadii[j]);
      }
    }
  }

  animate(time: number) {
    this.spine.animate(time);
    this.head.animate(time);
  }
};

export default Creature;
