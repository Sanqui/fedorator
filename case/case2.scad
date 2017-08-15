$fn=80;

TOLERANCE = 0.5;

RPI_LENGTH = 85;
RPI_WIDTH = 56;
RPI_LEFT_PORTS_WIDTH = 2.5;
RPI_HEIGHT = 5;

RPI_HEIGHT_FULL = RPI_HEIGHT + 14;
RPI_LENGTH_FULL = RPI_LENGTH + TOLERANCE;
RPI_WIDTH_FULL = RPI_WIDTH + RPI_LEFT_PORTS_WIDTH + TOLERANCE;

//DISPLAY_HEIGHT = 5;
//DISPLAY_PIN_HEIGHT = 14;

//RPI_HEIGHT_WITH_DISPLAY = RPI_HEIGHT_FULL + DISPLAY_HEIGHT;

USB_PORT_HOLE=[40, 22, 12.25];
USB_PLUG_WITH_CABLE_LENGTH = 60;
USB_PORT_LENGTH = 8; // approx.
USP_PLUG_WIDTH = 30; // approx.
USB_PLUG_HEIGHT = 5; // approx.
USB_PORT_SCREW_HOLE_DISTANCE = 7;
USB_PORT_SCREW_HOLE_RADIUS = 1.5 + 0.1;


RPI_DISPLAY_BOARD_DISTANCE = 8;
DISPLAY_BOARD_HEIGHT = 1;
DISPLAY_BOARD_LENGTH = 66;

// values from https://www.raspberrypi.org/documentation/hardware/display/7InchDisplayDrawing-14092015.pdf
DISPLAY_BASE_LENGTH = 164.9;
DISPLAY_BASE_WIDTH = 100.6;
DISPLAY_BASE_THICKNESS = 2.5;
DISPLAY_BASE_OFF_BOARD_X = 48.45; 
DISPLAY_BASE_OFF_BOARD_Y = DISPLAY_BASE_WIDTH - RPI_WIDTH - 20.8; 

DISPLAY_LENGTH = 192.96;
DISPLAY_WIDTH = 110.76;
DISPLAY_THICKNESS = 1.4;

DISPLAY_ANCHOR_HEIGHT = 2;

DISPLAY_X_MISPLACEMENT_INNER = 5;
DISPLAY_X_MISPLACEMENT = -6.63 + DISPLAY_X_MISPLACEMENT_INNER;

SHELL_HEIGHT1 = 50;
SHELL_HEIGHT2 = 150 - SHELL_HEIGHT1;
SHELL_HEIGHT = SHELL_HEIGHT1 + SHELL_HEIGHT2;
SHELL_WIDTH = DISPLAY_BASE_WIDTH + 0.5 + DISPLAY_X_MISPLACEMENT_INNER;
SHELL_LENGTH = 135;
SHELL_THICKNESS = 4;

SHELL_ANGLE = -atan(SHELL_LENGTH/SHELL_HEIGHT2);
SHELL_TOP_LENGTH = sqrt(pow(SHELL_LENGTH, 2)+pow(SHELL_HEIGHT2,2));

/*RPI_POSITIONING = [(SHELL_WIDTH) / 2 - (RPI_WIDTH_FULL)/2,
                       0,
                       SHELL_TOP_LENGTH/6];
                       */
SHELL_TOP_TO_DISPLAY_BOTTOM = RPI_LENGTH * 1.2;
SHELL_BOTTOM_TO_DISPLAY = SHELL_TOP_LENGTH - SHELL_TOP_TO_DISPLAY_BOTTOM;
DISPLAY_POSITIONING = [(SHELL_WIDTH) / 2 - (RPI_WIDTH)/2,
                       0,
                       SHELL_TOP_LENGTH - SHELL_TOP_TO_DISPLAY_BOTTOM];

RUBBER_FOOT_DIAMETER = 17.5;
RUBBER_FOOT_HEIGHT = 9;


module prism(l, w, h){
    // from https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids
    polyhedron(
        points=[[0,0,0], [l,0,0], [l,w,0], [0,w,0], [0,w,h], [l,w,h]],
        faces=[[0,1,2,3],[5,4,3,2],[0,4,5,1],[0,3,4],[5,2,1]]
    );
}

/*module rpi_with_display_small() {
    // small display
    import("raspberry_pi_Bplus.STL", convexity=10);
    
    translate([0, RPI_LEFT_PORTS_WIDTH, RPI_HEIGHT+DISPLAY_PIN_HEIGHT])
        cube([RPI_LENGTH, RPI_WIDTH, DISPLAY_HEIGHT]);
    
    // double usb plug
    translate([RPI_LENGTH-USB_PORT_LENGTH, RPI_WIDTH-USP_PLUG_WIDTH, 13])
        cube([USB_PLUG_WITH_CABLE_LENGTH, USP_PLUG_WIDTH, USB_PLUG_HEIGHT]);
}*/


module display_anchor() {
    translate([0, 0, DISPLAY_ANCHOR_HEIGHT*2])
    cube([10, 5, DISPLAY_ANCHOR_HEIGHT], center=true);
}

module rpi_with_display() {
    translate([27, 47, 0]) // XXX
    translate([RPI_WIDTH_FULL, RPI_LENGTH, -RPI_DISPLAY_BOARD_DISTANCE])
    rotate([0, 180, 90]) {
        color("gray")
        import("raspberry_pi_Bplus.STL", convexity=10);
        
        // double usb plug
        translate([RPI_LENGTH-USB_PORT_LENGTH, RPI_WIDTH-USP_PLUG_WIDTH, 13])
            cube([USB_PLUG_WITH_CABLE_LENGTH, USP_PLUG_WIDTH, USB_PLUG_HEIGHT]);
        
        translate([0, RPI_LEFT_PORTS_WIDTH, -RPI_DISPLAY_BOARD_DISTANCE])
        {
         display();
        }
    }
}


module display() {
    cube([DISPLAY_BOARD_LENGTH, RPI_WIDTH, DISPLAY_BOARD_HEIGHT]);
        translate([-DISPLAY_BASE_OFF_BOARD_X, -DISPLAY_BASE_OFF_BOARD_Y, -DISPLAY_BASE_THICKNESS - 2])
        {
            cube([DISPLAY_BASE_LENGTH, DISPLAY_BASE_WIDTH, DISPLAY_BASE_THICKNESS]);
            
            
            x1 = 20.0;
            x2 = 20.0 + 126.2;
            y1 = DISPLAY_BASE_WIDTH + 6.63 - 21.58;
            y2 = DISPLAY_BASE_WIDTH + 6.63 - 21.58 - 65.65;
            
            translate([x1, y1, -0.3])
                display_anchor();
            translate([x2, y1, -0.3])
                display_anchor();
            translate([x1, y2, -0.3])
                display_anchor();
            translate([x2, y2, -0.3])
                display_anchor();
            
            translate([-11.89, -(DISPLAY_WIDTH - DISPLAY_BASE_WIDTH - 6.63), - 0.3])
            cube([DISPLAY_LENGTH, DISPLAY_WIDTH, DISPLAY_THICKNESS]);
        }
}

module rpid() {
    color("gray")
    translate([0,0,RPI_LENGTH])
    rotate([90,90,0])
        rpi_with_display();
}


module rounded_rect(size, radius) {
    x = size[0];
    y = size[1];
    hull() {
        for (xp = [0, 1]) {
            for (yp = [0, 1]) {
                translate([(xp*x)+(xp-0.5)*-2*(radius/2),
                           (yp*y)+(yp-0.5)*-2*(radius/2), 0])
                    circle(r=radius);
            }
        }
    }
}


module rounded_cube(size, radius, thickness) {
    x = size[0];
    y = size[1];
    z = size[2];

    linear_extrude(height=z)
        difference() {
            rounded_rect(size, radius);
            if(thickness != -1) {
                translate([thickness/2, thickness/2, 0])
                rounded_rect([size[0]-thickness, size[1]-thickness], radius);
            }
        }
}

module rpi_support_prism() {
    w = RPI_WIDTH/4;
    h = tan(90+SHELL_ANGLE)*RPI_LENGTH-RPI_HEIGHT;
    l = sqrt(pow(RPI_LENGTH, 2) - pow(h, 2));
    prism(w,
        l,
        h);
    
    translate([0, 0, -SHELL_HEIGHT1])
        cube([w, l/5, SHELL_HEIGHT1]);
    
    translate([0, l - l/5, -SHELL_HEIGHT1])
        cube([w, l/5, SHELL_HEIGHT1]);
}

module rpi_support() {
    rpi_support_prism();
    translate([RPI_WIDTH - RPI_WIDTH/4, 0, 0])
        rpi_support_prism();
}

ANCHOR_SUPPORT_SIZE = 8;
ANCHOR_SUPPORT_DEPTH = 5.5;
ANCHOR_SUPPORT_SPOT_DEPTH = 5.5;
ANCHOR_SUPPORT_OFF_TOP = DISPLAY_ANCHOR_HEIGHT+4.5;

ANCHOR_SCREW_RADIUS = 1.5 + 0.1;

module shell_anchor_support() {
    translate([0, 0, -ANCHOR_SUPPORT_OFF_TOP - ANCHOR_SUPPORT_DEPTH])
    cube([SHELL_WIDTH + SHELL_THICKNESS, ANCHOR_SUPPORT_SIZE, ANCHOR_SUPPORT_DEPTH]);
}
module shell_anchor_extension() {
    translate([-ANCHOR_SUPPORT_SIZE/2, -ANCHOR_SUPPORT_SIZE/2, -ANCHOR_SUPPORT_OFF_TOP-ANCHOR_SUPPORT_SPOT_DEPTH])
    cube([ANCHOR_SUPPORT_SIZE, ANCHOR_SUPPORT_SIZE, ANCHOR_SUPPORT_SPOT_DEPTH]);
}

module shell_anchor_hole() {
    translate([0, 0, -ANCHOR_SUPPORT_OFF_TOP-ANCHOR_SUPPORT_SPOT_DEPTH])
    cylinder(h=ANCHOR_SUPPORT_SPOT_DEPTH, r=ANCHOR_SCREW_RADIUS);
}

module rubber_feet_indent() {
    translate([-SHELL_THICKNESS/2, -SHELL_THICKNESS/2, 0]) {
        cube([RUBBER_FOOT_DIAMETER+SHELL_THICKNESS, RUBBER_FOOT_DIAMETER+SHELL_THICKNESS, RUBBER_FOOT_HEIGHT+SHELL_THICKNESS]);
        // screw
        translate([SHELL_THICKNESS/2 + RUBBER_FOOT_DIAMETER/2, SHELL_THICKNESS/2 + RUBBER_FOOT_DIAMETER/2, RUBBER_FOOT_HEIGHT])
            cylinder(h=10+TOLERANCE, r=USB_PORT_SCREW_HOLE_RADIUS+SHELL_THICKNESS/5);
    }
}

module rubber_feet_indent_hole() {
    translate([-TOLERANCE, -TOLERANCE, -TOLERANCE]) {
        cube([RUBBER_FOOT_DIAMETER + TOLERANCE*2, RUBBER_FOOT_DIAMETER + TOLERANCE*2, RUBBER_FOOT_HEIGHT]);
        // screw
        translate([(RUBBER_FOOT_DIAMETER+TOLERANCE*2)/2, (RUBBER_FOOT_DIAMETER+TOLERANCE*2)/2, RUBBER_FOOT_HEIGHT])
            cylinder(h=10, r=USB_PORT_SCREW_HOLE_RADIUS);
    }
}

module shell() {
    //rounded_cube([SHELL_WIDTH, SHELL_LENGTH, SHELL_HEIGHT1], SHELL_THICKNESS, SHELL_THICKNESS);
    difference() {
        union() {
            difference() {
                minkowski() {
                    prism(SHELL_WIDTH, SHELL_LENGTH, SHELL_HEIGHT2);
                    cylinder(r=SHELL_THICKNESS,h=SHELL_HEIGHT1+SHELL_THICKNESS);
                }
                translate([0, 0, 0])
                minkowski() {
                    prism(SHELL_WIDTH, SHELL_LENGTH, SHELL_HEIGHT2);
                    cylinder(r=1,h=SHELL_HEIGHT1+SHELL_THICKNESS);
                }
            }
            
            // floor
            translate([SHELL_WIDTH/2 - SHELL_WIDTH/8, -SHELL_THICKNESS, 0])
                cube([SHELL_WIDTH/4, SHELL_LENGTH + SHELL_THICKNESS*2, SHELL_THICKNESS]);
            translate([0, -SHELL_THICKNESS + SHELL_LENGTH/2, 0])
                cube([SHELL_WIDTH, SHELL_LENGTH/8, SHELL_THICKNESS]);
            
            // prism to back wall
            translate([-SHELL_THICKNESS*0.5, SHELL_LENGTH-SHELL_THICKNESS*2+1, 0])
                prism(SHELL_WIDTH+SHELL_THICKNESS, SHELL_THICKNESS*2, SHELL_THICKNESS*2);
            
            // prism to sides
            translate([SHELL_THICKNESS*1.5, -SHELL_THICKNESS/2, 0])
            rotate([0, 0, 90])
                prism(SHELL_LENGTH+SHELL_THICKNESS, SHELL_THICKNESS*2, SHELL_THICKNESS*2);
            
            translate([SHELL_WIDTH - SHELL_THICKNESS*1.5, SHELL_LENGTH, 0])
            rotate([0, 0, 270])
                prism(SHELL_LENGTH+SHELL_THICKNESS, SHELL_THICKNESS*2, SHELL_THICKNESS*2);
            
            
            x1 = 0;
            x2 = SHELL_WIDTH - RUBBER_FOOT_DIAMETER;
            y1 = 0;
            y2 = -SHELL_THICKNESS + SHELL_LENGTH/2;
            y3 = SHELL_LENGTH - RUBBER_FOOT_DIAMETER - SHELL_THICKNESS/2;
            translate([x1, y1, 0])
                rubber_feet_indent();
            translate([x2, y1, 0])
                rubber_feet_indent();
            //translate([x1, y2, 0])
            //    rubber_feet_indent();
            //translate([x2, y2, 0])
            //    rubber_feet_indent();
            translate([x1, y3, 0])
                rubber_feet_indent();
            translate([x2, y3, 0])
                rubber_feet_indent();
        }
        // holes
        union() {
            // hole for display
            translate([0, 0, SHELL_HEIGHT1+SHELL_THICKNESS*2])
            rotate([SHELL_ANGLE, 0, 0])
            translate([-TOLERANCE, 0, -TOLERANCE])
                cube([SHELL_WIDTH,
                    SHELL_THICKNESS,
                    SHELL_TOP_LENGTH]);
            
            // hole for usb port
            translate([(SHELL_WIDTH) / 2 - (USB_PORT_HOLE[0])/2,
                    -SHELL_THICKNESS,
                    SHELL_HEIGHT1/2-USB_PORT_HOLE[2]])
                cube(USB_PORT_HOLE);
            
            // holes for screws for usb port
            
            translate([(SHELL_WIDTH) / 2 - (USB_PORT_HOLE[0])/2 - USB_PORT_SCREW_HOLE_DISTANCE,
                    -SHELL_THICKNESS,
                    SHELL_HEIGHT1/2-(USB_PORT_HOLE[2]/2)])
            rotate([90, 0, 0])
                cylinder(h=ANCHOR_SUPPORT_SPOT_DEPTH, r=USB_PORT_SCREW_HOLE_RADIUS);
            
            translate([(SHELL_WIDTH) / 2 + (USB_PORT_HOLE[0])/2 + USB_PORT_SCREW_HOLE_DISTANCE,
                    -SHELL_THICKNESS,
                    SHELL_HEIGHT1/2-(USB_PORT_HOLE[2]/2)])
            rotate([90, 0, 0])
                cylinder(h=ANCHOR_SUPPORT_SPOT_DEPTH, r=USB_PORT_SCREW_HOLE_RADIUS);
            
            // we'll do without the back wall
            
            translate([0, SHELL_LENGTH, SHELL_THICKNESS*4])
            cube([SHELL_WIDTH, SHELL_THICKNESS, SHELL_HEIGHT+SHELL_THICKNESS]);
            
            // rubber feet indent holes
            
            
            x1 = 0;
            x2 = SHELL_WIDTH - RUBBER_FOOT_DIAMETER;
            y1 = 0;
            y2 = -SHELL_THICKNESS + SHELL_LENGTH/2;
            y3 = SHELL_LENGTH - RUBBER_FOOT_DIAMETER - SHELL_THICKNESS/2;
            translate([0, 0, 0])
                rubber_feet_indent_hole();
            translate([x2, 0, 0])
                rubber_feet_indent_hole();
            //translate([0, y2, 0])
            //    rubber_feet_indent_hole();
            //translate([x2, y2, 0])
            //    rubber_feet_indent_hole();
            translate([0, y3, 0])
                rubber_feet_indent_hole();
            translate([x2, y3, 0])
                rubber_feet_indent_hole();
        }
    }
    /*
    translate([-SHELL_THICKNESS/4, SHELL_LENGTH-SHELL_THICKNESS/2, SHELL_HEIGHT-SHELL_THICKNESS+SHELL_THICKNESS])
        cube([SHELL_WIDTH+SHELL_THICKNESS/2, SHELL_THICKNESS, SHELL_THICKNESS]);
    */
    
    // front display hold
    translate([0, -SHELL_THICKNESS*0.5, SHELL_HEIGHT1])
    minkowski() {
        cube([SHELL_WIDTH, 0.01, SHELL_HEIGHT1*0.25]);
        cylinder(r=SHELL_THICKNESS/2,h=0.001);
    }
    
    
    // anchor supports
    x1 = SHELL_THICKNESS + DISPLAY_LENGTH - (12.54 + 20.0 + 126.2);
    x2 = x1 + 126.2;
    y1 = DISPLAY_X_MISPLACEMENT + 21.58;
    y2 = DISPLAY_X_MISPLACEMENT + 21.58 + 65.65;
    //y1 = DISPLAY_BASE_WIDTH + 6.63 - 21.58;
    //y2 = DISPLAY_BASE_WIDTH + 6.63 - 21.58 - 65.65;
    translate([0, 0, SHELL_HEIGHT1+SHELL_THICKNESS])
    rotate([90+SHELL_ANGLE, 0, 0])
    {
        translate([0, 0, DISPLAY_THICKNESS])
        difference() {
            union() {
                translate([-SHELL_THICKNESS/2, x1 - ANCHOR_SUPPORT_SIZE/2, 0])
                    shell_anchor_support();
                translate([-SHELL_THICKNESS/2, x2 - ANCHOR_SUPPORT_SIZE/2, 0])
                    shell_anchor_support();
                translate([y1, x1, 0])
                    shell_anchor_extension();
                translate([y1, x2, 0])
                    shell_anchor_extension();
                translate([y2, x1, 0])
                    shell_anchor_extension();
                translate([y2, x2, 0])
                    shell_anchor_extension();
            }
            translate([y1, x1, 0])
                shell_anchor_hole();
            translate([y1, x2, 0])
                shell_anchor_hole();
            translate([y2, x1, 0])
                shell_anchor_hole();
            translate([y2, x2, 0])
                shell_anchor_hole();
        }
    }
    
    /*translate([-120, 0, 0])
    for (i = [0 : 50])
        translate([18*(i % 6), 0, 10 * floor(i / 6)])
        cube([17.5, 17.5, 9]);
    */
    //21.58 - 6.63 + SHELL_THICKNESS + ANCHOR_SUPPORT_SIZE
}


//translate(DISPLAY_POSITIONING)
//translate([-RPI_LEFT_PORTS_WIDTH, 0, RPI_LENGTH])
//

//translate([0, -SHELL_BOTTOM_TO_DISPLAY*sin(SHELL_ANGLE), SHELL_BOTTOM_TO_DISPLAY*cos(SHELL_ANGLE)])
//translate([0, 0, SHELL_HEIGHT1+SHELL_THICKNESS])
//rotate([SHELL_ANGLE, 0, 0])
//translate([0, 0, RPI_LENGTH])
//rotate([90, 90, 0])

translate([DISPLAY_X_MISPLACEMENT, 0, 0])
translate([0, 0, SHELL_HEIGHT1+SHELL_THICKNESS])
rotate([90+SHELL_ANGLE, 0, 0])
translate([0, SHELL_THICKNESS, 0])
%rpi_with_display();


translate([200, 0, 0])// -RPI_HEIGHT_WITH_DISPLAY])
%rpi_with_display();


FRONT_TO_RPI = 50;
GROUND_TO_RPI =
    SHELL_HEIGHT
    - (SHELL_TOP_TO_DISPLAY_BOTTOM / SHELL_TOP_LENGTH) * SHELL_HEIGHT2
    - (SHELL_LENGTH/SHELL_TOP_LENGTH)*RPI_HEIGHT_WITH_DISPLAY;

/*
translate([(SHELL_WIDTH) / 2 - (RPI_WIDTH)/2,
    FRONT_TO_RPI,
    GROUND_TO_RPI])
rpi_support();*/

//shell();

difference() {
    shell();
    union() {
        translate([-10, SHELL_LENGTH + SHELL_THICKNESS, 0])
        cube([300, 100, 800]);
        /*
        translate([-10, 0, -10])
        cube([200, 200, 200]);
        translate([-10, -10, 20])
        cube([200, 200, 200]);
        */
        /*
        translate([-10, -10, 0])
        cube([200, 200, 48]);
        translate([-10, 40, 0])
        cube([200, 200, 70]);
        translate([-10, 60, 0])
        cube([200, 200, 85]);
        translate([-10, 80, 0])
        cube([200, 200, 400]);
        */
        /*
        translate([-10, -10, -10])
        cube([200, 200, 60]);
        rotate([90+SHELL_ANGLE, 0, 0])
        translate([-10, 0, -62])
        cube([200, 200, 100]);
        */
    }
}
