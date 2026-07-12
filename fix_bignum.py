import re

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if re.search(r'^\s*static func', line):
        new_lines.append(line.replace('static func', 'nonisolated static func'))
    elif re.search(r'^\s*init\(', line) and 'nonisolated' not in line:
        new_lines.append(line.replace('init(', 'nonisolated init('))
    elif re.search(r'^\s*func ', line) and 'nonisolated' not in line:
        new_lines.append(line.replace('func ', 'nonisolated func '))
    else:
        new_lines.append(line)

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "w") as f:
    f.writelines(new_lines)

