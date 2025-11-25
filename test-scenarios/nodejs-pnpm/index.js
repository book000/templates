const { format } = require('date-fns');

console.log('Testing Node.js pnpm CI workflow');
console.log('Current date:', format(new Date(), 'yyyy-MM-dd'));

// Simple test
const testDate = new Date('2024-01-01');
const formatted = format(testDate, 'MMMM dd, yyyy');
console.log('Formatted date:', formatted);

// Exit with success
process.exit(0);