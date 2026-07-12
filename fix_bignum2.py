import re

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if re.search(r'^\s*mutating func ', line) and 'nonisolated' not in line:
        new_lines.append(line.replace('mutating func', 'nonisolated mutating func'))
    elif re.search(r'^\s*private func ', line) and 'nonisolated' not in line:
        new_lines.append(line.replace('private func', 'nonisolated private func'))
    elif re.search(r'^\s*static let ', line) and 'nonisolated' not in line:
        new_lines.append(line.replace('static let', 'nonisolated static let'))
    else:
        new_lines.append(line)

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "w") as f:
    f.writelines(new_lines)
