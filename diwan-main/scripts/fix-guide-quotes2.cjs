/**
 * Fix all quote/string issues in guide TypeScript files.
 * Converts all problematic string literals to template literals (backtick strings)
 * which can contain both ' and " without any escaping.
 */
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'src', 'lib', 'userGuides', 'guides');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.ts'));

function fixFile(filepath) {
  let content = fs.readFileSync(filepath, 'utf8');
  let changed = false;

  // We need to find all string LITERALS that are values (not keys or import paths).
  // Strategy: look for property value patterns where the string value is the problem.
  // Instead of complex parsing, we'll fix specific known-bad patterns:

  // Pattern 1: Double-quoted string that ends with ', instead of ",
  // e.g., description: "foo bar baz',
  // Fix: change the trailing ', to ",
  const fixMixedTerminator = (text) => {
    // Match: " ... ', where the string was supposed to end with "
    // This is tricky because we need to be careful about nested quotes
    return text.replace(/"([^"]*)',(\s*$)/gm, (match, inner, trailing) => {
      // Only fix if this looks like a value line (not inside another string)
      changed = true;
      return '"' + inner + '"' + trailing;
    });
  };

  // Pattern 2: Double-quoted string containing unescaped " (broken by earlier regex)
  // e.g., "staff member"s profile
  // This is very hard to fix automatically without knowing the original intent.
  // Best approach: convert these lines to use template literals.

  // COMPREHENSIVE FIX: Process the file line by line and fix string values
  // by converting to template literals where there are quote issues.

  let lines = content.split('\n');
  let fixedLines = lines.map((line, lineIdx) => {
    // Skip import lines and type annotation lines
    if (line.trim().startsWith('import ') || line.trim().startsWith('//')) return line;

    // Fix: line has a double-quoted string ending with ', (mixed terminator)
    // Pattern: (key): "...content...',
    const mixedEnd = line.match(/^(\s*(?:description|a|q|body|tip|markdown|tagline|title|summary|caption|alt|audience|label|role):\s*)"(.*)',(\s*)$/);
    if (mixedEnd) {
      const [, prefix, inner, suffix] = mixedEnd;
      // Convert to template literal to handle all quote types
      const fixedInner = inner.replace(/\\"/g, '"').replace(/\\'/g, "'");
      changed = true;
      return prefix + '`' + fixedInner + '`,' + suffix;
    }

    // Fix: double-quoted string spanning the whole value but containing unescaped "
    // This means the string is actually broken - has extra " inside
    // Pattern: detect lines where there are unescaped " in the middle of a string value
    const doubleQuoteValue = line.match(/^(\s*(?:description|a|q|body|tip|markdown|tagline|title|summary|caption|alt|audience|label|role):\s*)"(.*)",(\s*)$/);
    if (doubleQuoteValue) {
      const [, prefix, inner, suffix] = doubleQuoteValue;
      // Check if inner contains unescaped double quotes (broken strings)
      if (inner.includes('"')) {
        // Convert to template literal
        const fixedInner = inner.replace(/\\"/g, '"').replace(/\\'/g, "'");
        changed = true;
        return prefix + '`' + fixedInner + '`,' + suffix;
      }
    }

    // Fix: single-quoted string containing \' (SWC compatibility)
    // Convert to template literal
    const singleQuoteValue = line.match(/^(\s*(?:description|a|q|body|tip|markdown|tagline|title|summary|caption|alt|audience|label):\s*)'((?:[^'\\]|\\.)*)',(\s*)$/);
    if (singleQuoteValue) {
      const [, prefix, inner, suffix] = singleQuoteValue;
      if (inner.includes("\\'")) {
        const fixedInner = inner.replace(/\\'/g, "'").replace(/`/g, '\\`');
        changed = true;
        return prefix + '`' + fixedInner + '`,' + suffix;
      }
    }

    return line;
  });

  const result = fixedLines.join('\n');

  // Also handle multi-line string issues that span beyond single lines
  // For now, write the result

  if (changed || result !== content) {
    fs.writeFileSync(filepath, result, 'utf8');
    console.log(`Fixed: ${path.basename(filepath)}`);
  } else {
    console.log(`Clean: ${path.basename(filepath)}`);
  }
}

files.forEach(f => fixFile(path.join(dir, f)));
console.log('\nDone.');
