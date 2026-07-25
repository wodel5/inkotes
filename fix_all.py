import os

basedir = r"E:\FlutterProject\foledge\lib\pickcolor"

# File 1: recent_colors_view.dart - remove ColorPreset, ColorPresetsView, PresetLibraryView, PresetLibraryEntry
path = os.path.join(basedir, "widgets", "recent_colors_view.dart")
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

result = []
skip_depth = 0
skip_classes = ["class ColorPreset", "class ColorPresetsView", "class PresetLibraryView", "class PresetLibraryEntry"]
in_skip = False
import_color_picker_storage = "import '../utils/color_picker_storage.dart';"

for line in lines:
    # Remove import of color_picker_storage
    if import_color_picker_storage in line:
        continue
    
    # Check if we're entering a class to skip
    should_skip = False
    for cls in skip_classes:
        if line.strip().startswith(cls):
            should_skip = True
            break
    
    if should_skip:
        in_skip = True
        skip_depth = 1
        continue
    
    if in_skip:
        # Track brace depth to know when the class ends
        for ch in line:
            if ch == "{":
                skip_depth += 1
            if ch == "}":
                skip_depth -= 1
        if skip_depth <= 0:
            in_skip = False
        continue
    
    result.append(line)

with open(path, "w", encoding="utf-8") as f:
    f.writelines(result)
print(f"recent_colors_view.dart: {len(lines)} -> {len(result)} lines")

# File 2: pickcolor.dart - remove default_preset_library export
path = os.path.join(basedir, "pickcolor.dart")
with open(path, "r", encoding="utf-8") as f:
    content = f.read()
content = content.replace("export 'utils/default_preset_library.dart';\n", "")
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("pickcolor.dart: removed default_preset_library export")

print("\nDone!")
