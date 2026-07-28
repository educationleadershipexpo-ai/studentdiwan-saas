with open("src/App.tsx", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "/exams" in line.lower() or "exams" in line.lower():
        print(f"Line {i+1}: {line.strip()[:120]}")
