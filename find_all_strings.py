import os
import re

def find_all_strings(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.swift'): continue
            if "Localization.swift" in file: continue
            
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Regex to find anything inside quotes
            # It will find a lot of false positives (system images, variable names)
            # but we can filter it roughly
            
            for line_no, line in enumerate(content.split('\n'), 1):
                # Ignore lines with 'tr(' or 'localized' or 'Image('
                if 'tr(' in line or 'localized' in line or 'Image(' in line: continue
                # Ignore print statements
                if 'print(' in line: continue
                
                # Find strings
                matches = re.findall(r'"([^"]*?[a-zA-ZàâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ][^"]*?)"', line)
                for m in matches:
                    if len(m.strip()) <= 1: continue
                    # skip typical system symbols or keys
                    if '.' in m and ' ' not in m: continue # e.g. "xmark.circle"
                    if m.startswith('UI'): continue
                    if 'color' in m.lower() or 'font' in m.lower(): continue
                    if m == 'Main': continue
                    if m == 'Duck Tycoon': continue
                    
                    print(f"{filepath}:{line_no}: {m}")

find_all_strings('/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources')
