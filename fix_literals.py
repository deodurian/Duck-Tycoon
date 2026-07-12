import re

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "r") as f:
    text = f.read()

# Replace mantissa == 0 with mantissa == 0.0
text = re.sub(r'mantissa == 0\b', 'mantissa == 0.0', text)
# Replace mantissa != 0 with mantissa != 0.0
text = re.sub(r'mantissa != 0\b', 'mantissa != 0.0', text)
# Replace mantissa < 0 with mantissa < 0.0
text = re.sub(r'mantissa < 0\b', 'mantissa < 0.0', text)

# Replace value == 0 in init
text = text.replace('if value == 0 ||', 'if value == 0.0 ||')
text = text.replace('let negative = value < 0', 'let negative = value < 0.0')

# Also check exp == 0 in pow
# pow takes exp: Double
text = text.replace('if exp == 0 {', 'if exp == 0.0 {')
text = text.replace('if exp == 1 {', 'if exp == 1.0 {')

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "w") as f:
    f.write(text)

