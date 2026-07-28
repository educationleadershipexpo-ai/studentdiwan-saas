with open("src/pages/academics/Gradebook.tsx", "r", encoding="utf-8") as f:
    lines = f.readlines()

words = ["smartdb", "getall", "gradebook", "invoice", "entry", "submission"]
for i, line in enumerate(lines):
    for w in words:
        if w in line.lower():
            print(f"Line {i+1}: {w} -> {line.strip()[:100]}")
