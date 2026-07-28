with open("src/pages/academics/Assessments.tsx", "r", encoding="utf-8") as f:
    lines = f.readlines()

words = ["highest", "lowest", "average", "maxMarks", "passingMarks", "academicYear", "status", "draft"]
for i, line in enumerate(lines):
    for w in words:
        if w in line.lower():
            print(f"Line {i+1}: {w} -> {line.strip()[:100]}")
