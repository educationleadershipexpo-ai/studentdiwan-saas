with open("src/pages/settings/RoomManagement.tsx", "r", encoding="utf-8") as f:
    lines = f.readlines()

words = ["building", "equipment", "assignedclasses", "capacity", "floor", "status", "roomname", "roomno", "type"]
for i, line in enumerate(lines):
    for w in words:
        if w in line.lower():
            print(f"Line {i+1}: {w} -> {line.strip()[:100]}")
