#!/bin/bash
# Multi-color Tailscale Framework Desktop Tile export script
# Exports each color as a separate STL file using OpenSCAD command line
#
# Usage: ./export-tailscale-tile.sh

set -e  # Exit on error

SCAD_FILE="tailscale-tile.scad"
OUTPUT_PREFIX="tailscale-tile"
OUTPUT_DIR="export"
OPENSCAD="openscad"

# Color definitions
declare -a COLORS=("black" "gray" "white")
declare -a COLOR_NAMES=("0-black" "1-gray" "2-white")

# check OpenSCAD is installed
if ! command -v $OPENSCAD &> /dev/null; then
    echo "Error: OpenSCAD not found in PATH"
    echo "Please install OpenSCAD or set OPENSCAD variable to the correct path"
    exit 1
fi

# check .scad file exists
if [ ! -f "$SCAD_FILE" ]; then
    echo "Error: $SCAD_FILE not found"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Starting multi-color export for Tailscale Framework Desktop Tile..."
echo "File: $SCAD_FILE"
echo "Using OpenSCAD: $(which $OPENSCAD)"
echo ""

# Export each color
for i in "${!COLORS[@]}"; do
    color_num=$i
    color_name="${COLOR_NAMES[$i]}"
    output_file="$OUTPUT_DIR/${OUTPUT_PREFIX}-${color_name}.stl"

    echo "[$((i+1))/${#COLORS[@]}] Rendering color $color_num (${COLORS[$i]})..."
    echo "  → Output: $output_file"

    # Render with current_color set to this color index
    $OPENSCAD -o "$output_file" \
              -D "current_color=$color_num" \
              "$SCAD_FILE" 2>&1 | grep -v "WARNING: Ignoring unknown" || true

    if [ -f "$output_file" ]; then
        size=$(du -h "$output_file" | cut -f1)
        echo "  ✓ Exported successfully ($size)"
    else
        echo "  ✗ Export failed"
        exit 1
    fi
    echo ""
done

echo "✓ All exports complete!"
echo ""
echo "Files exported to: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR/${OUTPUT_PREFIX}"*.stl 2>/dev/null || ls -lh "$OUTPUT_DIR/"
echo ""
echo "Next steps:"
echo "1. Import all STL files into Bambu Studio / Orca Slicer"
echo "2. In Objects panel, assign each part to correct filament slot:"
echo "   - ${OUTPUT_PREFIX}-0-black.stl → Black base filament"
echo "   - ${OUTPUT_PREFIX}-1-gray.stl  → Gray dots filament"
echo "   - ${OUTPUT_PREFIX}-2-white.stl → White T-shape filament"
echo "3. Slice and print!"
echo ""
