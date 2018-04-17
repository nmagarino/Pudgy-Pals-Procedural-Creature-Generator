import Spine from './Spine';
import Head from './Head';

class Creature {
  spine: Spine;
  head: Head;

  constructor() {
    this.spine = new Spine();
    this.head = new Head();
    
  }

  generate() {
    this.spine.generate();

    // Head takes information from the spine that is made previously
    this.head.generate(this.spine.metaBallPos, this.spine.metaBallRadii);
  }

  animate(time: number) {
    this.spine.animate(time);
    this.head.animate(time);
  }
};

export default Creature;
