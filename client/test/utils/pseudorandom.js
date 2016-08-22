'use strict';


let seed = 0;

function pseudoRandom() {
  const x = Math.sin(seed++) * 10000;
  return x - Math.floor(x);
}

for (let i = 0; i < 10; i++) pseudoRandom();

module.exports = pseudoRandom;
