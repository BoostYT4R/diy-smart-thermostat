// thermostat_front_bezel.scad - Print FACE DOWN (as exported). No supports.
// Thermostat wall enclosure v2 - 7" display on the front, electronics behind,
// separate vented sensor pod at the bottom (keeps the BME280 away from the heat).
//
// Open in OpenSCAD (free, openscad.org). F5 = quick preview, F6 = render,
// then File > Export > STL. Set part = "box" and export, then part = "bezel" and export.
// Print the box back-side down and the bezel face down (no supports needed for either).
//
// Coordinates: X = width, Y = height on the wall (0 = bottom), Z = out from the wall.
// Measure your parts and change the numbers in the first two sections before printing.

/* [Display - Waveshare ESP32-S3-Touch-LCD-7] */
disp_w      = 193.0;  // glass width (Waveshare spec 192.96)
disp_h      = 110.8;  // glass height (Waveshare spec 110.76)
disp_edge_t = 7.0;    // MEASURE: thickness at the EDGE of the display (glass + panel + board)
view_w      = 156;    // visible window (7" 800x480 active area is ~154 x 86)
view_h      = 88;
view_dx     = 0;      // shift the window if the picture isn't centered on the glass
view_dy     = 0;

/* [Inside the box] */
elec_d      = 34;     // depth behind the display for ESP32 + jumpers, relay, bucks, Wagos
pod_h       = 26;     // sensor pod height (mini breadboard + BME280 lying flat)

/* [USB cable to the display] */
usb_side    = "none"; // "none", "left", "right" or "bottom" - which display edge the USB-C plug exits
usb_pos     = 30;     // mm from the display's left edge (bottom) or bottom edge (left/right)
usb_w       = 14;     // slot size for the plug
usb_hh      = 9;

/* [Box] */
wall     = 1.8;   // side walls (4 lines with a 0.4 nozzle)
back_t   = 1.6;   // back plate against the wall
front    = 1.8;   // bezel front plate
m        = 9;     // frame border around the display (holds the 4 corner screws)
clr      = 0.4;   // gap around the display
ledge    = 3;     // how far the box's front rim overlaps the back edge of the display
ledge_t  = 2.0;
screw_d  = 4.5;   // wall screws
head_d   = 9;
m3_pilot = 2.6;   // M3 self-tapping screws hold the bezel on
m3_clear = 3.4;
m3_head  = 6.2;
slot_w   = 3;
slot_p   = 6;
corner_r = 5;     // rounded corners (seen from the front)
edge_r   = 1;     // rounded front edge of the bezel
lean     = true;  // lightening holes in the back + hollow bezel rim (less filament)
grid     = 16;    // lightening-hole size in the back
grid_bar = 5;     // bars between them (components stick to these with tape)

part = "bezel";    // "box", "bezel", "both" (preview only - export box and bezel separately), "test"

/* [Hidden] */
$fn = 40;
cav_w = disp_w + 2*clr;
rim_c = m - wall + clr + ledge;   // depth of the 45-degree slope under the rim
cav_h = disp_h + 2*clr;
ow = cav_w + 2*m;
yd = wall + pod_h + m;          // bottom of the display opening
oh = yd + cav_h + m;
od = back_t + elec_d;            // box depth
bz = front + disp_edge_t;        // bezel depth
div_y = wall + pod_h;            // divider (pod roof) starts here

posts = [[m/2, div_y + (m)/2 + 0.5], [ow - m/2, div_y + (m)/2 + 0.5],
         [m/2, oh - m/2],          [ow - m/2, oh - m/2]];

echo(str("Outer size: ", ow, " x ", oh, " mm, total depth ", od + bz, " mm"));

// rounded rectangle slab
module rrect(w, h, r, t) {
    linear_extrude(t) offset(r = r) offset(delta = -r) square([w, h]);
}
// bezel outline: rounded corners + rounded front edge (z = 0 is the front face)
module bezel_env() {
    steps = 6;
    hull() for (i = [0 : steps]) {
        z = edge_r * i / steps;
        inset = edge_r - sqrt(max(0, edge_r*edge_r - (edge_r - z)*(edge_r - z)));
        translate([inset, inset, z]) rrect(ow - 2*inset, oh - 2*inset, max(corner_r - inset, 0.5), 0.01);
    }
    translate([0, 0, edge_r]) rrect(ow, oh, corner_r, bz);
}
cav_r = max(corner_r - wall, 0.5);

module slots_x(x0, x1, y0, y1, z0, z1) {         // vertical slots across X
    n = floor((x1 - x0 - slot_w) / slot_p) + 1;
    for (i = [0 : n-1]) translate([x0 + i*slot_p, y0, z0]) cube([slot_w, y1 - y0, z1 - z0]);
}
module slots_z(y0, y1, z0, z1, x0, x1) {         // tall narrow slots on a side wall
    n = floor((y1 - y0 - slot_w) / slot_p) + 1;
    for (i = [0 : n-1]) translate([x0, y0 + i*slot_p, z0]) cube([x1 - x0, slot_w, z1 - z0]);
}
module countersunk_back(x, y) {
    translate([x, y, -1]) cylinder(d = screw_d, h = back_t + 2);
    translate([x, y, back_t + 2 - (head_d - screw_d)/2 + 0.01])
        cylinder(d1 = screw_d, d2 = head_d, h = (head_d - screw_d)/2);
}

module back_grid() {
    x0 = m + 2; x1 = ow - m - 2;                 // stay clear of the corner posts
    y0 = div_y + wall + m; y1 = oh - m - 2;
    nx = floor((x1 - x0 + grid_bar) / (grid + grid_bar));
    ny = floor((y1 - y0 + grid_bar) / (grid + grid_bar));
    sx = x0 + ((x1 - x0) - (nx*grid + (nx-1)*grid_bar)) / 2;
    sy = y0 + ((y1 - y0) - (ny*grid + (ny-1)*grid_bar)) / 2;
    for (i = [0 : nx-1], j = [0 : ny-1]) {
        cx = sx + i*(grid + grid_bar) + grid/2;
        cy = sy + j*(grid + grid_bar) + grid/2;
        keep = min([for (x = [m + 16, ow - m - 16], y = [div_y + wall + 14, oh - wall - 14])
                    max(abs(cx - x), abs(cy - y))]) < (head_d + 6)/2 + grid/2 + 1;
        if (!keep) translate([cx - grid/2, cy - grid/2, -1]) cube([grid, grid, back_t + 2]);
    }
}

module box() { intersection() { box_raw(); translate([0, 0, -1]) rrect(ow, oh, corner_r, od + 2); } }

module box_raw() {
    difference() {
        union() {
            difference() {
                cube([ow, oh, od]);
                // electronics cavity
                translate([wall, div_y + wall, back_t]) rrect(ow - 2*wall, oh - div_y - 2*wall, cav_r, od);
                // sensor pod cavity
                translate([wall, wall, back_t]) rrect(ow - 2*wall, pod_h, cav_r, od);
            }
            // thicker pads under the wall screws (back is thin)
            for (x = [m + 16, ow - m - 16], y = [div_y + wall + 14, oh - wall - 14])
                translate([x, y, 0]) cylinder(d = head_d + 6, h = back_t + 2);
            // corner posts for the bezel screws
            for (p = posts) translate([p[0], p[1], 0]) cylinder(d = m, h = od);
            // front rim that holds the display from behind.
            // Its underside is a 45-degree slope so it prints without supports.
            difference() {
                translate([wall, div_y + wall, od - ledge_t - rim_c])
                    cube([ow - 2*wall, oh - div_y - 2*wall, ledge_t + rim_c]);
                hull() {
                    translate([wall, div_y + wall, od - ledge_t - rim_c - 0.01])
                        cube([ow - 2*wall, oh - div_y - 2*wall, 0.01]);
                    translate([m + clr + ledge, yd + clr + ledge, od - ledge_t])
                        cube([disp_w - 2*ledge, disp_h - 2*ledge, 0.01]);
                }
                translate([m + clr + ledge, yd + clr + ledge, od - ledge_t - 1])
                    cube([disp_w - 2*ledge, disp_h - 2*ledge, ledge_t + 2]);
            }
        }
        // M3 pilot holes
        for (p = posts) translate([p[0], p[1], od - 16]) cylinder(d = m3_pilot, h = 17);
        // wall-cable hole (centre of the back, behind the display)
        translate([ow/2 - 15, yd + cav_h/2 - 20, -1]) cube([30, 40, back_t + 2]);
        // wall screws
        for (x = [m + 16, ow - m - 16], y = [div_y + wall + 14, oh - wall - 14]) countersunk_back(x, y);
        // notch in the pod roof for the 4 sensor wires (at the back)
        translate([ow/2 - 8, div_y - 1, back_t]) cube([16, wall + 2, 7]);
        // lightening grid in the back of the electronics area (the pod back stays solid)
        if (lean) back_grid();
        // vents: top (hot air out), low on the sides of the electronics (air in)
        slots_x(m + 10, ow - m - 10, oh - wall - 1, oh + 1, back_t + 4, od - ledge_t - rim_c - 2);
        for (x = [-1, ow - wall - 1]) slots_z(div_y + wall + 6, div_y + wall + 40, back_t + 4, od - ledge_t - rim_c - 2, x, x + wall + 2);
        // vents: sensor pod bottom and sides (room air)
        slots_x(wall + 8, ow - wall - 8, -1, wall + 1, wall + 5, od - 4);
        for (x = [-1, ow - wall - 1]) slots_z(wall + 4, wall + pod_h - 4, back_t + 4, od - 4, x, x + wall + 2);
        // optional USB plug slot through the box side at display level
        if (usb_side == "left")   translate([-1, yd + clr + usb_pos, od - ledge_t - usb_hh]) cube([m + 2, usb_w, usb_hh + 1]);
        if (usb_side == "right")  translate([ow - m - 1, yd + clr + usb_pos, od - ledge_t - usb_hh]) cube([m + 2, usb_w, usb_hh + 1]);
        if (usb_side == "bottom") translate([m + clr + usb_pos, div_y - 1, od - ledge_t - usb_hh]) cube([usb_w, m + wall + 2, usb_hh + 1]);
    }
}

// Bezel, modelled face-down: z = 0 is the front face you see.
module bezel() { intersection() { bezel_raw(); bezel_env(); } }

module bezel_raw() {
    difference() {
        cube([ow, oh, bz]);
        // display pocket
        translate([m, yd, front]) cube([cav_w, cav_h, bz]);
        // window
        translate([m + clr + disp_w/2 + view_dx - view_w/2, yd + clr + disp_h/2 + view_dy - view_h/2, -1])
            cube([view_w, view_h, front + 2]);
        // sensor pod: open behind, slotted front
        translate([wall, wall, front]) rrect(ow - 2*wall, pod_h, cav_r, bz);
        slots_x(wall + 10, ow - wall - 10, wall + 5, wall + pod_h - 5, -1, front + 1);
        // hollow rim (keeps 1 wall outside, 1.6 mm around the display pocket, solid corners)
        if (lean) difference() {
            translate([wall, div_y + wall, front]) rrect(ow - 2*wall, oh - div_y - 2*wall, cav_r, bz);
            translate([m - 1.6, yd - 1.6, front - 1]) cube([cav_w + 3.2, cav_h + 3.2, bz + 2]);
            for (p = posts) translate([p[0], p[1], 0]) cylinder(d = m + 3, h = bz + 1);
        }
        // corner screws (countersunk from the front)
        for (p = posts) {
            translate([p[0], p[1], -1]) cylinder(d = m3_clear, h = bz + 2);
            translate([p[0], p[1], -0.01]) cylinder(d1 = m3_head, d2 = m3_clear, h = (m3_head - m3_clear)/2);
        }
        // matching USB slot in the bezel rim
        if (usb_side == "left")   translate([-1, yd + clr + usb_pos, front]) cube([m + 2, usb_w, bz]);
        if (usb_side == "right")  translate([ow - m - 1, yd + clr + usb_pos, front]) cube([m + 2, usb_w, bz]);
        if (usb_side == "bottom") translate([m + clr + usb_pos, div_y - 1, front]) cube([usb_w, m + wall + 2, bz]);
    }
}

if (part == "box") box();
if (part == "bezel") bezel();
// ~20 min print: thin slice of the bezel. Drop the display in face-down to check the
// outline, window position and corner screw spacing before printing the real parts.
if (part == "test") intersection() { bezel(); translate([-1, -1, -1]) cube([ow + 2, oh + 2, front + 3 + 1]); }
if (part == "both") {
    color("SlateGray") box();
    // preview only (don't export this one) - bezel shown in place on the front
    color("Gainsboro") translate([0, 0, od + bz]) mirror([0, 0, 1]) bezel();
}
