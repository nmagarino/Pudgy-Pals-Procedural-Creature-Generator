import Spine from './Spine';
import Head from './Head';
import Limb from './Limb';
import {vec2, vec3} from 'gl-matrix';
import Appendage from './Appendage';

class Creature {
  spine: Spine;
  spineLocations: number[];
  head: Head;
  limbs: Limb[];
  jointLocations: number[];
  jointRadii: number[];
  limbLengths: number[];
  appendages: Appendage;

  constructor() {
  }

  generate() {
    this.spine = new Spine();
    this.spineLocations = [];
    this.head = new Head();
    this.limbs = [];

    this.jointLocations = [];
    this.jointRadii = [];
    this.limbLengths = [];

    this.appendages = new Appendage();

    this.spine.generate();
    for (let i = 0; i < this.spine.metaBallPos.length; i++) {
      let spinePos = this.spine.metaBallPos[i];
      this.spineLocations.push(spinePos[0]);
      this.spineLocations.push(spinePos[1]);
      this.spineLocations.push(spinePos[2]);
    }

    // Head takes information from the spine that is made previously
    this.head.generate(this.spineLocations, this.spine.metaBallRadii);

    this.appendages.generate(this.limbLengths, this.jointLocations);

    //Leg generation and parsing
    let numLimbs = Math.pow(Math.random(), 1.7) * 4;
    let generatingArms = false;
    for (let i = 0; i < numLimbs; i++) {
      let limb1 = new Limb(!generatingArms);
      let offset = (Math.random() * this.spine.metaBallPos.length/numLimbs) * 0.8;
      let spineIndex = this.spine.metaBallPos.length - 1 - Math.max(Math.min(Math.floor(i * this.spine.metaBallPos.length/numLimbs + offset), this.spine.metaBallPos.length - 1), 0);
      let startPos = this.spine.metaBallPos[spineIndex];
      startPos[2] += this.spine.metaBallRadii[spineIndex]/2 + 0.1;
      limb1.generate(startPos, this.spine.metaBallRadii[spineIndex] * 0.7);

      let limb2 = new Limb(true);
      for (let j = 0; j < limb1.jointPos.length; j++) {
        limb2.jointPos.push(vec3.multiply(vec3.create(), limb1.jointPos[j], vec3.fromValues(1, 1, -1)));
        limb2.jointRadii.push(limb1.jointRadii[j]);
      }

      this.limbs.push(limb1);
      this.limbs.push(limb2);

      if (Math.random() > 0.6) generatingArms = true;
    }

    for (let i = 0; i < this.limbs.length; i++) {
      let leg = this.limbs[i];
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
