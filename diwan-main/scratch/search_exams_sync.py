import os

words = ["sd_exams", "examstore", "getexams", "persistexam"]
for root, dirs, files in os.walk("src"):
    for file in files:
        if file.endswith((".ts", ".tsx", ".js", ".jsx")):
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                for w in words:
                    if w in content.lower():
                        print(f"Found {w} in {path}")
            except Exception:
                pass
