// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause
//
// Framework Desktop Tile with Tailscale Logo
//
// Color scheme:
// - Color 0 (black): tile base
// - Color 1 (gray): corner dots + top center dot
// - Color 2 (white): T-shaped dots (entire middle row + center bottom dot)
//
// Export:
// 1. Run ./export-tailscale-tile.sh to generate all STL files
// 2. Import all STLs into slicer, assign colors
//
// Adapted from https://www.printables.com/model/1397765-framework-desktop-tile-generator CC BY 4.0 https://creativecommons.org/licenses/by/4.0/

// Multi-color export control
// Colors: 0 = black (base), 1 = gray (corner dots), 2 = white (T-shape)
current_color = -1;  // -1 = show all (preview), 0/1/2 = export single color

// Tile dimensions
tile_size = 28.5;      // Width and height of the tile
tile_thickness = 2.6;  // Thickness of the tile
hook_cube = [3.0, 1.0, 2.0];  // Dimensions of the notches

// Bevel and notch parameters
inset_padding = 0.55;              // Size of the inset bevel
hook_offset = 5.5;                 // Distance of notches from edges
inset_corner_depth = 0.3;          // The inset depth of the corners of the tile

// Logo parameters
dot_rad = 2.6;
dot_height = 0.8;  // Height of dots (thicker than layer height for reliable printing)
logo_size = dot_rad * 8;

// multi-color export
module colorpart(n) {
    if (current_color == -1 || current_color == n) {
        children();
    }
}

// tile base
module tile_base() {
    inset_size = tile_size - inset_padding;
    half_tile = tile_size / 2;

    colorpart(0) color("black") difference() {
        union() {
            translate([inset_padding / 2, inset_padding / 2, 0])
                cube([inset_size, inset_size, tile_thickness], center = true);

            translate([-half_tile + inset_corner_depth / 2, -half_tile + inset_corner_depth / 2, tile_thickness / 2 - 1])
                cube([tile_size, tile_size, 1]);
        }

        corner_cutout = [9, 9, inset_corner_depth];

        // bottom left
        translate([-half_tile, -half_tile, -tile_thickness / 2])
            cube(corner_cutout);

        // bottom right
        translate([-half_tile, half_tile - corner_cutout[1], -tile_thickness / 2])
            cube(corner_cutout);

        // top left
        translate([half_tile - corner_cutout[0], -half_tile, -tile_thickness / 2])
            cube(corner_cutout);

        // top right
        translate([half_tile - corner_cutout[0], half_tile - corner_cutout[1], -tile_thickness / 2])
            cube(corner_cutout);
    }
}

// inset notches with angle and clip
module hook_with_clip(position, angle) {
    translate(position)
        translate([0.0, 0.0, -hook_cube[2] / 2])
        rotate([0, 0, angle]) { // rotate the notch at the specified angle
            union() {
                // base notch cube
                cube(hook_cube, center = true);

                // triangular clip
                translate([-hook_cube[0] / 2, hook_cube[1] / 2, 0]) // position triangle at top of the notch
                    rotate([0, 90, 0])
                    linear_extrude(height = hook_cube[0])
                    polygon(points = [
                        [hook_cube[2] / 2, 0],  // top of triangle
                        [0.5, 0],                  // bottom-right of the triangle
                        [0.5, 0.5]                 // bottom-left of the triangle
                    ]);
            }
        }
}

// add corner notches with clips
module add_hooks() {
    half_tile = tile_size / 2;
    vertical_offset = -tile_thickness / 2 + inset_corner_depth;

    colorpart(0) color("black") {
        hook_with_clip([half_tile - hook_offset, half_tile - hook_offset, vertical_offset], -45);      // top-right
        hook_with_clip([-half_tile + hook_offset, half_tile - hook_offset, vertical_offset], 45);      // top-left
        hook_with_clip([half_tile - hook_offset, -half_tile + hook_offset, vertical_offset], -135);    // bottom-right
        hook_with_clip([-half_tile + hook_offset, -half_tile + hook_offset, vertical_offset], 135);    // bottom-left
    }
}

// create a T-shaped notch
module constraint(position) {
    constraint_cube = [3.1, 0.7, 1.7];
    translate(position) {
    translate([0.0, 0.0, -constraint_cube[2] / 2]) {
            // base notch cube
            cube(constraint_cube, center = true);

            // perpendicular cube for T-shape
            translate([0, -constraint_cube[1], 0])
                cube([constraint_cube[0] / 4, constraint_cube[1], constraint_cube[2]], center = true);
        }
    }
}

// add edge constraints (T-shaped notches)
module add_constraints() {
    half_tile = tile_size / 2;

    colorpart(0) color("black") {
        // Left edge
        rotate([0, 0, 90])
            constraint([0, half_tile - inset_padding * 2, -tile_thickness / 2]);

        // Right edge
        rotate([0, 0, -90])
            constraint([0, half_tile - inset_padding, -tile_thickness / 2]);
    }
}

// complete Framework tile with hooks and constraints
module framework_tile() {
    tile_base();
    add_hooks();
    add_constraints();
}

// individual dot - creates a cylinder flush with the surface
module dot(x, y) {
    dr = dot_rad;
    translate([dr + x*dr*3, dr + y*dr*3, 0])
        cylinder(h=dot_height, r=dot_rad, center=false);
}

// gray dots: corners + top center
module gray_dots() {
    colorpart(1) translate([0, 0, tile_thickness/2 - dot_height])
        color("gray") {
            dot(0, 0);  // bottom-left
            dot(2, 0);  // bottom-right
            dot(0, 2);  // top-left
            dot(1, 2);  // top-center
            dot(2, 2);  // top-right
        }
}

// white dots: T-shaped pattern
module accent_dots() {
    colorpart(2) translate([0, 0, tile_thickness/2 - dot_height])
        color("white") {
            dot(0, 1);  // left middle
            dot(1, 1);  // center middle
            dot(2, 1);  // right middle
            dot(1, 0);  // center bottom
        }
}

// all dots combined (for cutting recesses in base)
module all_dots() {
    translate([0, 0, tile_thickness/2 - dot_height]) {
        for (x = [0:2], y = [0:2]) dot(x, y);
    }
}

// tile with Tailscale logo
module tailscale_tile() {
    // center the logo on the tile
    logo_offset = (tile_size - logo_size) / 2;
    half_tile = tile_size / 2;

    // create recesses for the dot matrix
    difference() {
        framework_tile();
        translate([-half_tile + logo_offset, -half_tile + logo_offset, 0])
            all_dots();
    }

    // populate the gray & white dots
    translate([-half_tile + logo_offset, -half_tile + logo_offset, 0]) {
        gray_dots();
        accent_dots();
    }
}

// render flipped for printing
$fs = 0.15;
rotate([0, 180, 0])
    tailscale_tile();
