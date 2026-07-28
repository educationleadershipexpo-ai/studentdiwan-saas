/**
 * Comprehensive quote fixer for guide files.
 * Fixes ALL mixed quote terminators, including inside arrays.
 */
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'src', 'lib', 'userGuides', 'guides');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.ts'));

/**
 * Fix a single source string that may have mismatched quote delimiters.
 * We walk through looking for all string literals and fix their terminators.
 */
function fixLine(line) {
  // We'll rebuild the line character by character, tracking string state.
  let result = '';
  let i = 0;
  let changed = false;

  while (i < line.length) {
    const ch = line[i];

    // Start of a string literal?
    if (ch === '"' || ch === "'") {
      const openQ = ch;
      const closeQ = openQ === '"' ? "'" : '"'; // the WRONG closing quote
      result += openQ;
      i++;

      // Collect the string content
      let content = '';
      while (i < line.length) {
        const c = line[i];

        if (c === '\\') {
          // Escape sequence — consume both chars
          content += c;
          i++;
          if (i < line.length) {
            content += line[i];
            i++;
          }
          continue;
        }

        if (c === openQ) {
          // Correct closing quote
          content += c;
          i++;
          break;
        }

        if (c === closeQ) {
          // Wrong closing quote! Fix it.
          // But only if what follows suggests this is truly the end of the string
          // (followed by , ] } ; \n or another quote-like character)
          const next = i + 1 < line.length ? line[i + 1] : '';
          if (next === ',' || next === ']' || next === '}' || next === ';' || next === '' || next === '\n') {
            // Fix: use the correct closing quote
            content += openQ; // replace closeQ with openQ
            i++;
            changed = true;
            break;
          } else {
            // Part of the content (e.g., quote inside string)
            content += c;
            i++;
          }
          continue;
        }

        content += c;
        i++;
      }

      result += content;
      continue;
    }

    result += ch;
    i++;
  }

  return changed ? result : null;
}

let totalFixed = 0;

files.forEach(filename => {
  const filepath = path.join(dir, filename);
  const lines = fs.readFileSync(filepath, 'utf8').split('\n');
  let changed = false;

  const fixedLines = lines.map((line, i) => {
    const result = fixLine(line);
    if (result !== null) {
      totalFixed++;
      changed = true;
      return result;
    }
    return line;
  });

  if (changed) {
    fs.writeFileSync(filepath, fixedLines.join('\n'), 'utf8');
    console.log(`Fixed: ${filename}`);
  } else {
    console.log(`Clean: ${filename}`);
  }
});

console.log(`\nTotal lines fixed: ${totalFixed}`);
