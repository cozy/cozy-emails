'use strict';


let seed = process.env.PSEUDORANDOMSEED === undefined ? Math.random() :
    parseInt(process.env.PSEUDORANDOMSEED, 10);

// eslint-disable-next-line no-console
console.log('SEED is', seed);

function pseudoRandom() {
  const x = Math.sin(seed++) * 10000;
  return x - Math.floor(x);
}

for (let i = 0; i < 10; i++) pseudoRandom();

module.exports = pseudoRandom;
