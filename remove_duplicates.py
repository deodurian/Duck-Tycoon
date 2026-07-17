import sys

file_path = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift"
with open(file_path, "r") as f:
    lines = f.readlines()

new_lines = []
current_dict = set()

for line in lines:
    if ".french: [" in line or ".english: [" in line or ".spanish: [" in line or ".fr: [" in line or ".en: [" in line or ".es: [" in line:
        current_dict = set()
        new_lines.append(line)
        continue
    
    if ":" in line and "\"" in line:
        parts = line.split(":")
        if len(parts) >= 2:
            # extract key
            key = parts[0].strip()
            if key in current_dict:
                # it's a duplicate, SKIP it!
                continue
            else:
                current_dict.add(key)
                new_lines.append(line)
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

# Let's fix missing commas before right brackets ']' just in case!
for i in range(len(new_lines) - 1):
    if new_lines[i+1].strip() == "]," or new_lines[i+1].strip() == "]":
        # The line before bracket should NOT have a comma
        if new_lines[i].strip().endswith(","):
            new_lines[i] = new_lines[i].rstrip(",\n") + "\n"
    elif new_lines[i].strip() != "" and ":" in new_lines[i] and "\"" in new_lines[i] and new_lines[i].strip().endswith("\""):
        # The line is a key-value but missing a comma, and the next line is NOT a bracket
        if new_lines[i+1].strip() != "" and not new_lines[i+1].strip().startswith("//"):
            # Add a comma!
            new_lines[i] = new_lines[i].rstrip("\n") + ",\n"

with open(file_path, "w") as f:
    f.writelines(new_lines)

print("Duplicates removed and commas fixed!")
