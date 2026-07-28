with open("src/pages/academics/Exams.tsx", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "smartdb" in line.lower() or "getall" in line.lower() or "watch" in line.lower():
        print(f"Line {i+1}: {line.strip()[:120]}")
