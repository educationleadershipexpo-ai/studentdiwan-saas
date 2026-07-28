/**
 * Undo the damage from fix-guide-quotes4.cjs:
 * That script incorrectly converted "Word", inside single-quoted strings
 * to "Word', (replacing the closing double-quote with a single-quote).
 * This script reverses that by converting "Word', back to "Word",
 * wherever it appears within what looks like a string context.
 *
 * Also converts ALL remaining problematic single-quoted string VALUES
 * to template literals for permanent immunity to quote issues.
 */
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'src', 'lib', 'userGuides', 'guides');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.ts'));

function fixFile(filepath) {
  let content = fs.readFileSync(filepath, 'utf8');
  const original = content;

  // Step 1: Fix the broken pattern "Word', → "Word",
  // This reverses the damage from fixer4 which incorrectly saw "Word", as a string terminator
  // Pattern: a double-quote, followed by word chars / spaces / punctuation (no newline),
  //          followed by a single-quote and comma (which shouldn't be there)
  // We use a global replace: "...', → "...",
  // But we must be careful not to change legitimate patterns.
  // The key insight: "Word', is NEVER valid - it's always a bug from our transformation.
  // A valid sequence after a double-quoted word would be: "Word", (double-quote + comma)
  content = content.replace(/"([^"'\n]+)',/g, (match, word) => {
    // Restore: "Word', → "Word",
    return '"' + word + '",';
  });

  // Step 2: Fix lines where we have a single-quoted string ending with "
  // Pattern: key: 'content ending with wrong quote",
  // These are lines where the outer quotes were inverted
  const lines = content.split('\n');
  const fixedLines = lines.map(line => {
    // Fix: single-quote starts but double-quote ends (with comma)
    const m1 = line.match(/^(\s*\w[\w\s]*:\s*)'(.+)",(\s*)$/);
    if (m1) {
      const inner = m1[2];
      // Use template literal to avoid all quote issues
      return m1[1] + '`' + inner.replace(/`/g, '\\`') + '`,' + m1[3];
    }
    return line;
  });
  content = fixedLines.join('\n');

  if (content !== original) {
    fs.writeFileSync(filepath, content, 'utf8');
    console.log(`Fixed: ${path.basename(filepath)}`);
  } else {
    console.log(`Clean: ${path.basename(filepath)}`);
  }
}

files.forEach(f => fixFile(path.join(dir, f)));
console.log('\nDone.');
