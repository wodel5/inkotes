import os

basedir = r"E:\FlutterProject\foledge\lib\pickcolor"

# Fix pickcolor.dart - remove default_preset_library export
path = os.path.join(basedir, "pickcolor.dart")
with open(path, "r", encoding="utf-8") as f:
    content = f.read()
content = content.replace("export 'utils/default_preset_library.dart';\n", "")
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated pickcolor.dart")

# Check recent_colors_view.dart
path2 = os.path.join(basedir, "widgets", "recent_colors_view.dart")
with open(path2, "r", encoding="utf-8") as f:
    lines = f.readlines()
print(f"recent_colors_view.dart: {len(lines)} lines")
