with open("src/lib/examStore.ts", "r", encoding="utf-8") as f:
    content = f.read()

import re
matches = re.findall(r".{0,100}smartDb\..{0,100}", content, re.IGNORECASE)
for m in matches:
    print(m)
