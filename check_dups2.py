import re
from collections import Counter

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

langs = ['\.fr', '\.en', '\.es']

for lang in langs:
    print(f"--- Checking {lang} ---")
    pattern = rf'{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: continue
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: continue
    insert_idx = start_idx + end_match.start()
    
    lang_content = content[start_idx:insert_idx]
    
    # Extract keys
    keys = re.findall(r'"([^"]+)":\s*"', lang_content)
    counts = Counter(keys)
    dups = [k for k, v in counts.items() if v > 1]
    if dups:
        print(f"DUPLICATES FOUND in {lang}: {dups}")
    else:
        print(f"No duplicates in {lang}")

