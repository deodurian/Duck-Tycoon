import re

with open("/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/BigNumber.swift", "r") as f:
    text = f.read()

# For Double variables (mantissa, value, sumMantissa, absMantissa, etc.)
# Replace var == 0.0 with var.isZero
text = re.sub(r'([a-zA-Z0-9_]+)\s*==\s*0\.0', r'\1.isZero', text)
text = re.sub(r'([a-zA-Z0-9_]+)\s*!=\s*0\.0', r'!\1.isZero', text)

# Replace var < 0.0 with var.sign == .minus or just var < (0.0 as Double)
# Actually, the safest way in Swift to avoid any ambiguity is to cast the literal:
# var == (0.0 as Double)
# var < (0.0 as Double)

