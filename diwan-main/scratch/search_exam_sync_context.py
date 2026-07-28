with open("src/lib/examStore.ts", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'smartDb.getAll("Exam")' in line:
        print(f"Line {i+1}: {line.strip()}")
        # print 20 lines around it
        start = max(0, i - 15)
        end = min(len(lines), i + 15)
        for idx in range(start, end):
            print(f"  {idx+1}: {lines[idx].strip()}")
