import os
import re

VIEWS_DIR = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views"

def patch_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We want to match Text("Literal") and replace with Text(tr("Literal"))
    # Literal should not contain backslashes (no interpolation) and no quotes inside.
    # We also avoid replacing Text(tr("...")) if it already exists.
    # regex: Text\(\s*"([^"\\]+)"\s*\)
    # wait, emojis shouldn't be translated if they are just emojis, but tr("💰") just returns "💰" anyway.
    
    # Match Text("...")
    new_content = re.sub(r'Text\(\s*"([^"\\]+)"\s*\)', r'Text(tr("\1"))', content)
    
    # Match Button("...")
    new_content = re.sub(r'Button\(\s*"([^"\\]+)"', r'Button(tr("\1")', new_content)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Patched {filepath}")

for root, dirs, files in os.walk(VIEWS_DIR):
    for file in files:
        if file.endswith(".swift"):
            patch_file(os.path.join(root, file))

