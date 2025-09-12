const _ = require('lodash');

console.log('Testing Node.js CI workflow');
console.log('Lodash version:', _.VERSION);

// Simple test
const numbers = [1, 2, 3, 4, 5];
const doubled = _.map(numbers, n => n * 2);
console.log('Doubled numbers:', doubled);

// Exit with success
process.exit(0);