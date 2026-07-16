import re

loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Extract keys from each lang section
def extract_keys(content, lang):
    pattern = rf'\.{lang}:\s*\['
    match = re.search(pattern, content)
    if not match: return set()
    start_idx = match.end()
    end_match = re.search(r'\n    \]', content[start_idx:])
    if not end_match: return set()
    lang_content = content[start_idx:start_idx + end_match.start()]
    keys = re.findall(r'"([^"]+)":\s*"', lang_content)
    return set(keys)

fr_keys = extract_keys(content, 'fr')
en_keys = extract_keys(content, 'en')
es_keys = extract_keys(content, 'es')

# Read all tr() keys used in codebase
with open('/tmp/all_tr_keys.txt', 'r', encoding='utf-8') as f:
    used_keys = set(line.strip() for line in f if line.strip())

# Find missing
missing_en = sorted(used_keys - en_keys)
missing_es = sorted(used_keys - es_keys)
missing_fr = sorted(used_keys - fr_keys)

print(f"=== STATS ===")
print(f"Total tr() keys used in code: {len(used_keys)}")
print(f"FR dict size: {len(fr_keys)}")
print(f"EN dict size: {len(en_keys)}")
print(f"ES dict size: {len(es_keys)}")
print(f"Missing from FR: {len(missing_fr)}")
print(f"Missing from EN: {len(missing_en)}")
print(f"Missing from ES: {len(missing_es)}")
print()
print("=== MISSING FROM EN ===")
for k in missing_en:
    print(f"  {k}")
print()
print("=== MISSING FROM ES ===")
for k in missing_es:
    print(f"  {k}")
print()
print("=== MISSING FROM FR ===")
for k in missing_fr:
    print(f"  {k}")
