/**
 * Fix quote issues in guide TypeScript files.
 * Converts single-quoted strings containing apostrophes to double-quoted strings.
 */
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'src', 'lib', 'userGuides', 'guides');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.ts'));

function fixFile(filepath) {
  let content = fs.readFileSync(filepath, 'utf8');
  let changed = false;

  // Strategy: walk character by character, tracking string state.
  // When we find a single-quoted string that contains an unescaped apostrophe
  // (i.e., a single-quoted string that the parser would fail on), convert it.
  // Since our files may have BOTH:
  //   1. '...\'s...' (escaped — valid but SWC sometimes struggles)
  //   2. '...school"s...' (from our broken regex — needs fixing)
  // We'll do a simpler targeted replacement.

  // Step 1: Fix the broken pattern introduced by the buggy regex:
  // "...\\"s..." patterns (double-quote string with \" in it that shouldn't be there)
  // These look like: "...school\"s instance.',
  // We need to fix these by removing the \" and the trailing ',

  // Step 2: Simple approach — find all `\'` occurrences and replace with `'`
  // in double-quoted strings, or ensure the whole string is double-quoted.

  // The safest approach: for each string literal in the file,
  // if it's single-quoted and contains \', convert to double-quoted.

  // We'll use a regex that carefully matches single-quoted strings.
  // Single-quoted string: starts with ', ends with unescaped ', allows \' inside.
  // Pattern: '(?:[^'\\]|\\.)*'

  const result = content.replace(/'(?:[^'\\]|\\.)*'/g, (match) => {
    // Check if this is an object key (we don't want to change those)
    // Object keys in TypeScript: 'keyName': -> keep as-is
    // Content strings: '...value...' -> may need conversion

    // Only convert if the string contains \' (escaped apostrophe)
    if (!match.includes("\\'")) {
      return match; // No issue, keep original
    }

    // Convert to double-quoted string
    // 1. Remove the outer single quotes
    let inner = match.slice(1, -1);
    // 2. Un-escape the apostrophes
    inner = inner.replace(/\\'/g, "'");
    // 3. Escape any double quotes in the content (unlikely but safe)
    inner = inner.replace(/"/g, '\\"');
    changed = true;
    return '"' + inner + '"';
  });

  // Also fix the broken pattern from the previous bad regex:
  // These look like double-quoted strings ending with ', instead of ",
  // e.g., "...school\"s instance.',
  // Pattern: fix by removing \\" and fixing the terminator
  const result2 = result.replace(/"([^"]*)\\"s([^"]*)',/g, (match, before, after) => {
    changed = true;
    return '"' + before + "'s" + after + '",';
  });

  if (result2 !== content) {
    fs.writeFileSync(filepath, result2, 'utf8');
    console.log(`Fixed: ${path.basename(filepath)}`);
  } else {
    console.log(`Clean: ${path.basename(filepath)}`);
  }
}

files.forEach(f => fixFile(path.join(dir, f)));
console.log('\nDone. Check for any remaining issues.');
