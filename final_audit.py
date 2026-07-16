# -*- coding: utf-8 -*-
import re, subprocess, os

# Get ALL tr() keys from Swift source
src_dir = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/'
result = subprocess.run(['grep', '-roh', 'tr("[^"]*")', src_dir], capture_output=True, text=True)
raw_keys = set()
for line in result.stdout.strip().split('\n'):
    line = line.strip()
    if line.startswith('tr("') and line.endswith('")'):
        key = line[4:-2]
        raw_keys.add(key)

print(f"Total unique tr() keys in code: {len(raw_keys)}")

# Read Localization.swift
loc_path = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'
with open(loc_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Parse each lang section properly
def get_keys_for_lang(content, lang_marker):
    pattern = lang_marker + r':\s*\['
    match = re.search(pattern, content)
    if not match:
        return set()
    bracket_start = match.end()
    # Find matching ]
    depth = 1
    i = bracket_start
    while i < len(content) and depth > 0:
        if content[i] == '[':
            depth += 1
        elif content[i] == ']':
            depth -= 1
        i += 1
    section = content[bracket_start:i-1]
    
    # Extract keys - handle quotes properly
    keys = set()
    in_key = False
    current = []
    i = 0
    while i < len(section):
        c = section[i]
        if c == '"' and (i == 0 or section[i-1] != '\\'):
            if not in_key:
                in_key = True
                current = []
            else:
                in_key = False
                key_str = ''.join(current)
                # Next non-whitespace should be :
                j = i + 1
                while j < len(section) and section[j] in ' \t\n\r':
                    j += 1
                if j < len(section) and section[j] == ':':
                    keys.add(key_str)
                    # Skip the value
                    # find opening " of value
                    j += 1
                    while j < len(section) and section[j] in ' \t\n\r':
                        j += 1
                    if j < len(section) and section[j] == '"':
                        j += 1
                        while j < len(section):
                            if section[j] == '"' and section[j-1] != '\\':
                                break
                            j += 1
                    i = j
        elif in_key:
            current.append(c)
        i += 1
    return keys

fr_keys = get_keys_for_lang(content, '.fr')
en_keys = get_keys_for_lang(content, '.en')
es_keys = get_keys_for_lang(content, '.es')

print(f"FR keys: {len(fr_keys)}")
print(f"EN keys: {len(en_keys)}")
print(f"ES keys: {len(es_keys)}")

missing_fr = sorted(raw_keys - fr_keys)
missing_en = sorted(raw_keys - en_keys)
missing_es = sorted(raw_keys - es_keys)

print(f"\nMissing from FR: {len(missing_fr)}")
for k in missing_fr:
    if not all(ord(c) > 127 or c in '⭐️💰🦆🧬💎🎯💀🎒' for c in k):
        print(f"  [{repr(k)}]")

print(f"\nMissing from EN: {len(missing_en)}")
for k in missing_en:
    if not all(ord(c) > 127 or c in '⭐️💰🦆🧬💎🎯💀🎒' for c in k):
        print(f"  [{repr(k)}]")

print(f"\nMissing from ES: {len(missing_es)}")
for k in missing_es:
    if not all(ord(c) > 127 or c in '⭐️💰🦆🧬💎🎯💀🎒' for c in k):
        print(f"  [{repr(k)}]")
