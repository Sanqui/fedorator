$fn=80;

TOLERANCE = 0.5;

RPI_LENGTH = 85;
RPI_WIDTH = 56;
RPI_LEFT_PORTS_WIDTH = 2.5;
RPI_HEIGHT = 5;

RPI_HEIGHT_FULL = RPI_HEIGHT + 3 + TOLERANCE;
RPI_LENGTH_FULL = RPI_LENGTH + TOLERANCE;
RPI_WIDTH_FULL = RPI_WIDTH + RPI_LEFT_PORTS_WIDTH + TOLERANCE;

DISPLAY_HEIGHT = 5;
DISPLAY_PIN_HEIGHT = 14;

RPI_HEIGHT_WITH_DISPLAY = RPI_HEIGHT_FULL + DISPLAY_PIN_HEIGHT + DISPLAY_HEIGHT;

USB_PORT_HOLE=[40, 22, 10];
USB_PLUG_WITH_CABLE_LENGTH = 60;
USB_PORT_LENGTH = 8; // approx.
USP_PLUG_WIDTH = 30; // approx.


SHELL_HEIGHT1 = 50;
SHELL_HEIGHT2 = 120 - SHELL_HEIGHT1;
SHELL_HEIGHT = SHELL_HEIGHT1 + SHELL_HEIGHT2;
SHELL_WIDTH = 80;
SHELL_LENGTH = 130;
SHELL_THICKNESS = 5;

SHELL_ANGLE = -atan(SHELL_LENGTH/SHELL_HEIGHT2);
SHELL_TOP_LENGTH = sqrt(pow(SHELL_LENGTH, 2)+pow(SHELL_HEIGHT2,2));

/*RPI_POSITIONING = [(SHELL_WIDTH) / 2 - (RPI_WIDTH_FULL)/2,
                       0,
                       SHELL_TOP_LENGTH/6];
                       */
DISPLAY_POSITIONING = [(SHELL_WIDTH) / 2 - (RPI_WIDTH)/2,
                       0,
                       SHELL_TOP_LENGTH - RPI_LENGTH * 1.2];



module prism(l, w, h){
    // from https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids
    polyhedron(
        points=[[0,0,0], [l,0,0], [l,w,0], [0,w,0], [0,w,h], [l,w,h]],
        faces=[[0,1,2,3],[5,4,3,2],[0,4,5,1],[0,3,4],[5,2,1]]
    );
}

module rpi_with_display() {
    import("raspberry_pi_Bplus.STL", convexity=10);
    
    translate([0, RPI_LEFT_PORTS_WIDTH, RPI_HEIGHT+DISPLAY_PIN_HEIGHT])
        cube([RPI_LENGTH, RPI_WIDTH, DISPLAY_HEIGHT]);
    
    translate([RPI_LENGTH-USB_PORT_LENGTH, RPI_WIDTH-USP_PLUG_WIDTH, 0])
        cube([USB_PLUG_WITH_CABLE_LENGTH, USP_PLUG_WIDTH, 10]);
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


module shell() {
    //rounded_cube([SHELL_WIDTH, SHELL_LENGTH, SHELL_HEIGHT1], SHELL_THICKNESS, SHELL_THICKNESS);
    difference() {
        difference() {
            minkowski() {
                prism(SHELL_WIDTH, SHELL_LENGTH, SHELL_HEIGHT2);
                cylinder(r=SHELL_THICKNESS,h=SHELL_HEIGHT1+SHELL_THICKNESS);
            }
            translate([0, 0, SHELL_THICKNESS])
            minkowski() {
                prism(SHELL_WIDTH, SHELL_LENGTH, SHELL_HEIGHT2);
                cylinder(r=1,h=SHELL_HEIGHT1);
            }
        }
        // holes
        union() {
            // hole for display
            translate([0, 0, SHELL_HEIGHT1+SHELL_THICKNESS*2])
            rotate([SHELL_ANGLE, 0, 0])
            translate([-TOLERANCE, 0, -TOLERANCE])
            translate(DISPLAY_POSITIONING)
                cube([RPI_WIDTH + TOLERANCE*2,
                    SHELL_THICKNESS,
                    RPI_LENGTH + TOLERANCE*2]);
            
            // hole for usb port
            translate([(SHELL_WIDTH) / 2 - (USB_PORT_HOLE[0])/2,
                    -SHELL_THICKNESS,
                    SHELL_HEIGHT1/2-USB_PORT_HOLE[2]])
                cube(USB_PORT_HOLE);
        }
    }
    translate([-SHELL_THICKNESS/4, SHELL_LENGTH-SHELL_THICKNESS/2, SHELL_HEIGHT-SHELL_THICKNESS+SHELL_THICKNESS])
        cube([SHELL_WIDTH+SHELL_THICKNESS/2, SHELL_THICKNESS, SHELL_THICKNESS]);
}


translate([0, 0, SHELL_HEIGHT1+SHELL_THICKNESS*2])
rotate([SHELL_ANGLE, 0, 0])
translate(DISPLAY_POSITIONING)
translate([-RPI_LEFT_PORTS_WIDTH, RPI_HEIGHT_WITH_DISPLAY, RPI_LENGTH])
rotate([90, 90, 0])
rpi_with_display();

shell();
