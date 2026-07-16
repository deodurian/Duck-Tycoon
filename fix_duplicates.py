import re

filepath = '/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Models/Localization.swift'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

def deduplicate_dict(lang, text):
    # Find the dictionary for the language
    pattern = rf'(\.{lang}:\s*\[)(.*?)(\n\s*\])'
    match = re.search(pattern, text, re.DOTALL)
    if not match:
        return text
    
    dict_content = match.group(2)
    
    # Extract all key-value pairs
    # They look like: "Key": "Value", or "Key": "Value" without comma if it's the last one
    # Use a regex that captures the key and the rest of the line
    kv_pattern = r'^\s*"(.*?)":\s*"(.*?)",?\s*$'
    
    lines = dict_content.split('\n')
    
    seen_keys = set()
    deduped_lines = []
    
    # Read in reverse to keep the last occurrence
    for line in reversed(lines):
        if not line.strip():
            continue
        
        m = re.match(kv_pattern, line)
        if m:
            key = m.group(1)
            if key not in seen_keys:
                seen_keys.add(key)
                deduped_lines.append(line)
        else:
            # If line doesn't match standard kv pattern (e.g. multi-line), we keep it
            deduped_lines.append(line)
            
    deduped_lines.reverse()
    
    # Fix trailing commas
    for i in range(len(deduped_lines)):
        if i == len(deduped_lines) - 1:
            if deduped_lines[i].endswith(','):
                deduped_lines[i] = deduped_lines[i][:-1]
        else:
            if not deduped_lines[i].endswith(',') and '"' in deduped_lines[i]:
                deduped_lines[i] = deduped_lines[i] + ','
                
    new_dict_content = '\n'.join(deduped_lines)
    return text[:match.start(2)] + "\n" + new_dict_content + text[match.end(2):]

content = deduplicate_dict('fr', content)
content = deduplicate_dict('en', content)
content = deduplicate_dict('es', content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

