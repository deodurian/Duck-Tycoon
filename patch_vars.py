import os
import re

dir_path = "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/Views"

vars_to_wrap = [
    "loadingText",
    "option.rawValue",
    "sortOption.rawValue",
    "lang.rawValue",
    "style.rawValue",
    "title",
    "definition.type.title",
    "perk.name",
    "selected.rawValue",
    "rarity.shortName",
    "rarity.rawValue",
    "maxLabel",
    "tab.rawValue",
    "label",
    "upgrade.name",
    "perk.description",
    "perk.rarity.rawValue",
    "mission.title",
    "mission.description",
    "bestRarity.revealTitle",
    "upgrade.description",
    "crate.type.shortName",
    "item.rarity.rawValue",
    "name",
    "crate.type.rawValue",
    "duck.rarity.rawValue",
    "duck.size.rawValue",
    "duck.mutation.rawValue"
]

for root, dirs, files in os.walk(dir_path):
    for f in files:
        if f.endswith(".swift"):
            path = os.path.join(root, f)
            with open(path, 'r') as fp:
                content = fp.read()
            
            new_content = content
            for v in vars_to_wrap:
                new_content = re.sub(r'Text\(\s*' + re.escape(v) + r'\s*\)', f'Text(tr({v}))', new_content)
            
            # Special case for factory.name
            new_content = re.sub(r'Text\(\s*factory\.name\s*\)', r'Text(factory.name.replacingOccurrences(of: "Usine", with: tr("Usine")))', new_content)
            
            if new_content != content:
                with open(path, 'w') as fp:
                    fp.write(new_content)
                print(f"Patched vars in {f}")

