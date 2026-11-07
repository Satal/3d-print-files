// Wooden track joiners (v1.0)
// A short track with a peg at each end, for joining two socket (female) ends of
// wooden train track (Brio-style, IKEA LILLABO and similar). 40 mm wide, rounded
// edges all round.
//
// Peg position measured on real track: head centre 11.75 mm from the end face
// (wooden peg tip 18.1 mm out, socket far edge 18.5 mm). Sockets vary by brand:
// 13.3 mm on the set this was tested on, larger on some others, so set peg_width
// to about 0.5 mm under your socket.
//
// Print flat, as it sits on the floor. No supports.
// no-colour-knobs: no markings; the only text is an optional version marker underneath, off by default

/* [Track] */
// Length of the piece, end face to end face (mm). 54 matches the standard mini straight.
track_length = 54; // [20:1:210]

/* [Fit] */
// Peg head diameter (mm). 12.8 fits a 13.3 mm socket. Measure the round part of your socket and take off about 0.5.
peg_width = 12.8; // [10:0.1:17]

module __Customizer_Limit__() {}

function hide(x) = x;

// Brio standard (published)
track_w      = hide(40);
track_h      = hide(12);
groove_w     = hide(6);
groove_d     = hide(3);
groove_pitch = hide(26);
head_c       = hide(11.75);  // end face to head centre (measured: wooden peg tip 18.1, socket far edge 18.5, socket 13.3)
head_gap     = hide(0.8);    // plate joiner: gap round each head so it can flex
neck_w       = hide(6);      // inferred, typical
// House choices
peg_h        = hide(11);     // a little under track height so the peg never stands proud
lead_in      = hide(0.8);    // chamfer round the bottom of the head, to drop into the socket
edge_r       = hide(2);      // rounded top side edges for small hands
end_r        = hide(1.5);    // rounded top edge across each end
lip_r        = hide(0.8);    // rounded groove lips
base_ch      = hide(1);      // 45 degree chamfer round the bottom (prints without support)
top_round    = hide(0.8);    // rounded top edge on the peg heads
corner_r     = hide(3);      // rounded corners in plan
plate_t      = hide(1);
plate_len    = hide(56);     // runs about 25 mm under each track end
part         = hide("mini_track");  // plate_joiner exists but is untested
version_tag  = hide("");     // test prints: -D 'version_tag="tj v0.4"'
$fn          = hide(64);

// ---------- 2D shapes ----------

module rounded_rect(l, w, r) {
  offset(r) offset(-r) square([l, w], center = true);
}

// Track cross-section in the Y-Z plane: rounded top corners, rounded groove lips,
// chamfered bottom corners, two grooves.
module track_section() {
  intersection() {
    // grooves cut, then every convex corner (groove lips) rounded
    offset(r = lip_r) offset(delta = -lip_r) difference() {
      translate([-track_w/2, 0]) square([track_w, track_h]);
      for (s = [-1, 1]) translate([s*groove_pitch/2 - groove_w/2, track_h - groove_d]) square([groove_w, groove_d + 1]);
    }
    // outer shape: chamfered bottom, rounded top
    hull() {
      translate([-track_w/2 + base_ch, 0]) square([track_w - 2*base_ch, 0.01]);
      translate([-track_w/2, base_ch]) square([track_w, 0.01]);
      for (s = [-1, 1]) translate([s*(track_w/2 - edge_r), track_h - edge_r]) circle(edge_r);
    }
  }
}

// Side profile in the X-Z plane: rounded top edge and chamfered bottom edge at each end.
module track_side(len) {
  hull() {
    translate([-len/2 + base_ch, 0]) square([len - 2*base_ch, 0.01]);
    translate([-len/2, base_ch]) square([len, 0.01]);
    for (s = [-1, 1]) translate([s*(len/2 - end_r), track_h - end_r]) circle(end_r);
  }
}

// One peg in plan, pointing +X, starting at x = 0 (the end face).
// Neck and round head. inset shrinks it for the chamfered bands.
module peg_plan(width, inset = 0) {
  offset(-inset) {
    translate([-1, -neck_w/2]) square([head_c + 1, neck_w]);
    translate([head_c, 0]) circle(d = width);
  }
}

// ---------- 3D ----------

// A peg with a lead-in chamfer round the bottom of the head.
module peg(width, h) {
  n = 4;
  union() {
    translate([0, 0, lead_in]) linear_extrude(h - lead_in - top_round) peg_plan(width);
    // bottom band, inset by the lead-in, tapering out (45 degrees, no support)
    for (i = [0 : n - 1]) {
      z0 = i * lead_in / n;
      translate([0, 0, z0]) linear_extrude(lead_in / n + 0.01) peg_plan(width, lead_in - z0);
    }
    // top band, rounded in (no overhang going up)
    for (i = [0 : n - 1]) {
      dz = (i + 1) * top_round / n;
      inset = top_round - sqrt(max(0, top_round*top_round - dz*dz));
      translate([0, 0, h - top_round + i * top_round / n - 0.01]) linear_extrude(top_round / n + 0.01) peg_plan(width, inset);
    }
  }
}

module track_body(len) {
  intersection() {
    rotate([90, 0, 90]) translate([0, 0, -len/2]) linear_extrude(len) track_section();
    translate([0, 0, -1]) linear_extrude(track_h + 2) rounded_rect(len, track_w, corner_r);
    rotate([90, 0, 0]) translate([0, 0, -track_w/2 - 1]) linear_extrude(track_w + 2) track_side(len);
  }
}

module version_marker() {
  if (version_tag != "")
    // runs across the track, so it fits under the short fit test pieces too
    translate([-2, 0, -0.01]) rotate([0, 0, 90]) mirror([1, 0, 0]) linear_extrude(0.41)
      text(version_tag, size = 4, font = "Roboto:style=Bold", halign = "center", valign = "center");
}

module mini_track(len, width, label = "") {
  difference() {
    union() {
      track_body(len);
      translate([len/2, 0, 0]) peg(width, peg_h);
      translate([-len/2, 0, 0]) mirror([1, 0, 0]) peg(width, peg_h);
    }
    version_marker();
    if (label != "")
      translate([0, 0, track_h - 0.6]) linear_extrude(1)
        text(label, size = 6, font = "Roboto:style=Bold", halign = "center", valign = "center");
  }
}

module plate_joiner(width) {
  r = width/2 + head_gap;
  difference() {
    union() {
      difference() {
        // plate with a sloped edge so a track end rides up onto it
        hull() {
          linear_extrude(0.01) rounded_rect(plate_len, track_w, corner_r);
          translate([0, 0, plate_t - 0.01]) linear_extrude(0.01) rounded_rect(plate_len - 2*plate_t, track_w - 2*plate_t, corner_r);
        }
        // a gap round each head, so the head is held only by its neck and can flex
        for (s = [-1, 1]) translate([s*head_c, 0, -1]) cylinder(r = r, h = plate_t + 2);
      }
      // two pegs back to back, standing on the bed like a track's own pegs
      peg(width, peg_h);
      mirror([1, 0, 0]) peg(width, peg_h);
    }
    if (version_tag != "")
      translate([0, -track_w/2 + 4, -0.01]) mirror([1, 0, 0]) linear_extrude(0.41)
        text(version_tag, size = 4, font = "Roboto:style=Bold", halign = "center", valign = "bottom");
  }
}

if (part == "mini_track") mini_track(track_length, peg_width);
else if (part == "plate_joiner") plate_joiner(peg_width);
