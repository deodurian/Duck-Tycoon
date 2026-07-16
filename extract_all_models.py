import re
import os

files = [
    '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Upgrade.swift',
    '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/PrestigeUpgrade.swift',
    '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Factory.swift',
    '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Mission.swift'
]

texts_to_translate = set()

for fpath in files:
    if not os.path.exists(fpath): continue
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Extract name: "..." and description: "..." and effectDescription: "..."
    matches = re.findall(r'(?:name|description|effectDescription|taskDescription):\s*"([^"]+)"', content)
    for m in matches:
        texts_to_translate.add(m)

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    loc_content = f.read()

# Only print if not already present
for t in texts_to_translate:
    if f'"{t}"' not in loc_content:
        print(f"FR: {t}")

