import Spine from './Spine';

class Creature {
  spine: Spine;

  constructor() {
    this.spine = new Spine();
    
  }

  generate() {
    this.spine.generate();
  }

  animate(time: number) {
    this.spine.animate(time);
  }
};

export default Creature;
