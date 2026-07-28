with open("server.ts", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "async function dbcreatetable" in line.lower() or "function dbcreatetable" in line.lower():
        print(f"Line {i+1}: {line.strip()}")
        # print 20 lines after it
        for idx in range(i, min(len(lines), i + 25)):
            print(f"  {idx+1}: {lines[idx].strip()}")
        break
