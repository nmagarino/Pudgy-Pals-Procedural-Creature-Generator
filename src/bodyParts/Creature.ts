import Spine from 'Spine';

class Creature {
  spine: Spine;

  constructor() {
    this.spine = new Spine();
    
  }

  generate() {
    this.spine.generate();
  }
};

export default Creature;
