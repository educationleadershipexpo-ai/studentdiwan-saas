with open("src/pages/student/Assessments.tsx", "r", encoding="utf-8") as f:
    lines = f.readlines()

words = ["marks", "highest", "attempt", "result", "gradebook", "score"]
for i, line in enumerate(lines):
    for w in words:
        if w in line.lower():
            print(f"Line {i+1}: {w} -> {line.strip()[:100]}")
