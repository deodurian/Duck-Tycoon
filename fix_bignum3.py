import re

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if 'private mutating func ' in line and 'nonisolated' not in line:
        new_lines.append(line.replace('private mutating func', 'nonisolated private mutating func'))
    elif 'private func ' in line and 'nonisolated' not in line:
        new_lines.append(line.replace('private func', 'nonisolated private func'))
    else:
        new_lines.append(line)

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "w") as f:
    f.writelines(new_lines)

