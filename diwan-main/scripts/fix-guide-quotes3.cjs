/**
 * Fix mixed quote terminators in guide TypeScript files.
 * Handles: 'string ending with wrong quote", and vice versa.
 */
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'src', 'lib', 'userGuides', 'guides');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.ts'));

function fixLine(line) {
  // Pattern 1: starts with single quote, ends with double quote + comma
  // e.g.:  title: 'Some text",
  const m1 = line.match(/^(\s*\w[\w\s]*:\s*)'(.+)",(\s*)$/);
  if (m1) {
    // The content shouldn't have unescaped single quotes since we're fixing to single
    // Check if content has single quotes — if so, use template literal
    const inner = m1[2];
    if (inner.includes("'")) {
      return m1[1] + '`' + inner + '`,' + m1[3];
    }
    return m1[1] + "'" + inner + "'," + m1[3];
  }

  // Pattern 2: starts with double quote, ends with single quote + comma
  // e.g.:  description: "Some text with apostrophe's in it',
  const m2 = line.match(/^(\s*\w[\w\s]*:\s*)"(.+)',(\s*)$/);
  if (m2) {
    const inner = m2[2];
    // Content may have single quotes (that's why it was converted to double)
    // Check if it also has unescaped double quotes
    if (inner.includes('"')) {
      return m2[1] + '`' + inner.replace(/"/g, '"') + '`,' + m2[3];
    }
    return m2[1] + '"' + inner + '",' + m2[3];
  }

  return null; // no change
}

let totalFixed = 0;

files.forEach(filepath => {
  const fullPath = path.join(dir, filepath);
  const lines = fs.readFileSync(fullPath, 'utf8').split('\n');
  let changed = false;

  const fixedLines = lines.map((line, i) => {
    const result = fixLine(line);
    if (result !== null && result !== line) {
      changed = true;
      totalFixed++;
      return result;
    }
    return line;
  });

  if (changed) {
    fs.writeFileSync(fullPath, fixedLines.join('\n'), 'utf8');
    console.log(`Fixed: ${filepath}`);
  } else {
    console.log(`Clean: ${filepath}`);
  }
});

console.log(`\nTotal lines fixed: ${totalFixed}`);
