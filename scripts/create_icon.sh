#!/bin/bash
cd "$(dirname "$0")/.."

# Create icon using sips (built-in macOS tool) or generate programmatically
mkdir -p Assets.xcassets/AppIcon.appiconset

# Generate icon using Python (if available) or create a simple one
python3 << 'PYTHON_SCRIPT'
from PIL import Image, ImageDraw, ImageFont
import sys

size = 1024
img = Image.new('RGB', (size, size), color='#007AFF')
draw = ImageDraw.Draw(img)

# Draw clipboard shape
clipboard_x, clipboard_y = int(size * 0.2), int(size * 0.15)
clipboard_w, clipboard_h = int(size * 0.6), int(size * 0.7)

# Clipboard body (white rounded rectangle)
draw.rounded_rectangle(
    [(clipboard_x, clipboard_y), (clipboard_x + clipboard_w, clipboard_y + clipboard_h)],
    radius=size * 0.05,
    fill='white',
    outline='#E0E0E0',
    width=int(size * 0.01)
)

# Clipboard clip (top part)
clip_x = int(size * 0.35)
clip_y = int(size * 0.75)
clip_w = int(size * 0.3)
clip_h = int(size * 0.15)
draw.rounded_rectangle(
    [(clip_x, clip_y), (clip_x + clip_w, clip_y + clip_h)],
    radius=size * 0.03,
    fill='#C0C0C0'
)

# Lines on clipboard
for i in range(4):
    y = int(size * 0.3 + i * size * 0.1)
    draw.line(
        [(int(size * 0.3), y), (int(size * 0.7), y)],
        fill='#E0E0E0',
        width=int(size * 0.015)
    )

# Save
output_path = 'Assets.xcassets/AppIcon.appiconset/icon_1024.png'
img.save(output_path)
print(f"Icon created: {output_path}")
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo "Icon created successfully"
else
    echo "Python/PIL not available, creating simple icon with sips..."
    # Fallback: create a simple colored square
    sips -s format png --setProperty format png -z 1024 1024 -c "#007AFF" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns --out Assets.xcassets/AppIcon.appiconset/icon_1024.png 2>/dev/null || echo "Please install Pillow: pip3 install Pillow"
fi

