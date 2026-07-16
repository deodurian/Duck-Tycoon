import os
import re

def find_untranslated_strings(directory):
    patterns = [
        (r'Text\(\s*"([^"]+)"\s*\)', 'Text'),
        (r'Button\(\s*"([^"]+)"', 'Button'),
        (r'Label\(\s*"([^"]+)"', 'Label'),
        (r'Picker\(\s*"([^"]+)"', 'Picker'),
        (r'\.navigationTitle\(\s*"([^"]+)"', 'navigationTitle'),
        (r'\.alert\(\s*"([^"]+)"', 'alert')
    ]
    
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.swift'):
                continue
            
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
                # Check line by line for easier reporting
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    # skip if line contains 'tr(' or 'tr ("'
                    if 'tr(' in line or 'tr (' in line:
                        continue
                        
                    for pattern, name in patterns:
                        for match in re.finditer(pattern, line):
                            text = match.group(1)
                            # Ignore empty strings or pure symbols/numbers
                            if len(text.strip()) == 0: continue
                            if text.strip() in ['💰', '🧬', '⭐️', '💎']: continue
                            if re.match(r'^[\d\s\W]+$', text): continue # only numbers and symbols
                            
                            print(f"{filepath}:{i+1}: {name}(\"{text}\")")

find_untranslated_strings('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources')
