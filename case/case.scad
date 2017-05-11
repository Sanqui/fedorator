
TOLERANCE = 0.5;

RPI_LENGTH = 85;
RPI_WIDTH = 56;
RPI_LEFT_PORTS_WIDTH = 2.5;
RPI_HEIGHT = 5;

RPI_HEIGHT_FULL = RPI_HEIGHT + 3 + TOLERANCE;
RPI_LENGTH_FULL = RPI_LENGTH + TOLERANCE;
RPI_WIDTH_FULL = RPI_WIDTH + RPI_LEFT_PORTS_WIDTH + TOLERANCE;

RPI_WIDTH_ETHERNET = 20;
RPI_WIDTH_USB = RPI_WIDTH - RPI_WIDTH_ETHERNET;
RPI_HEIGHT_ETHERNET = 12;
RPI_HEIGHT_USB1 = 10;
RPI_LENGTH_ETHERNET = 2;
RPI_LENGTH_USB = 2;

DISPLAY_HEIGHT = 5;
DISPLAY_PIN_HEIGHT = 14;

RPID_HEIGHT = RPI_HEIGHT + DISPLAY_PIN_HEIGHT + DISPLAY_HEIGHT;

USB_PORT_WIDTH = 15;
USB_PORT_HEIGHT = 8;
USB_PORT_LENGTH = 10;

SHELL_HEIGHT = 220;
SHELL_WIDTH = 80;
SHELL_THICKNESS = 5;

BACK_SUPPORT_LENGTH = SHELL_WIDTH/8;
CABLE_HOLE_WIDTH = 20;

RPI_POSITIONING = [SHELL_WIDTH / 2 - (RPI_WIDTH_FULL)/2,
                       0,
                       SHELL_HEIGHT/2 - RPI_LENGTH_FULL/10];

NUM_USB_PORTS = 2;
USB_PORT_Z = RPI_POSITIONING[2] / 2;

PRISM_SUPPORT_HEIGHT = RPI_POSITIONING[2]/4;

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
    %cube([RPI_LENGTH, RPI_WIDTH, DISPLAY_HEIGHT]);
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
                translate([(xp*x)+(radius/2), (yp*y)+(radius/2), 0])
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
    difference() {
        union() {
            rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_THICKNESS], 5, -1);
            //rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_HEIGHT], 5, SHELL_THICKNESS);
        }
        
        color("red")
        union() {
            // hole for display
            translate([0, -RPID_HEIGHT, 0])
            translate(RPI_POSITIONING)
            translate([RPI_LEFT_PORTS_WIDTH, 0, 0])
                cube([RPI_WIDTH+TOLERANCE, RPID_HEIGHT*2, RPI_LENGTH+TOLERANCE]);
            
            // hole for power cable in the back
            translate([SHELL_WIDTH*0.1, SHELL_WIDTH, SHELL_THICKNESS])
                cube([CABLE_HOLE_WIDTH, CABLE_HOLE_WIDTH, CABLE_HOLE_WIDTH]);
    
            // holes for usb ports
            translate([SHELL_WIDTH/2 - USB_PORT_WIDTH/2, -USB_PORT_LENGTH, USB_PORT_Z])
                color("blue") cube([USB_PORT_WIDTH, USB_PORT_LENGTH*2, USB_PORT_HEIGHT]);
        }
    }
}

module support_pillar() {
    cube([(SHELL_WIDTH - RPI_WIDTH_FULL)/2,
          RPID_HEIGHT,
          RPI_POSITIONING[2] + RPI_LENGTH/2]);
}

module support_prism(l, w) {
    translate([0, w, 0])
    prism(l, -w, -PRISM_SUPPORT_HEIGHT );
}

module back_support_prism(offset) {
    translate([offset, BACK_SUPPORT_LENGTH + RPID_HEIGHT, 0])
        prism((SHELL_WIDTH - RPI_WIDTH_FULL)/2, -BACK_SUPPORT_LENGTH, -PRISM_SUPPORT_HEIGHT );
}

module back_support(height) {
    translate([0, 0, height]) {
        translate([0, RPI_POSITIONING[1] + RPID_HEIGHT, 0])
        cube([SHELL_WIDTH,
              BACK_SUPPORT_LENGTH,
              BACK_SUPPORT_LENGTH]);

        back_support_prism(0);
        back_support_prism(RPI_POSITIONING[0] + RPI_WIDTH_FULL + TOLERANCE);
    }
}

module supports() {
    translate([0, 0, 0])
        support_pillar();
    translate([RPI_POSITIONING[0] + RPI_WIDTH_FULL + TOLERANCE, 0, 0])
        support_pillar();
    
    // back support
    back_support(RPI_POSITIONING[2]);
    back_support(RPI_POSITIONING[2] + RPI_LENGTH/2);
    
    // ethernet support prism
    ethernet_prism_width = RPI_WIDTH_ETHERNET + RPI_LEFT_PORTS_WIDTH;
    translate([RPI_POSITIONING[0], 0, RPI_POSITIONING[2] - RPI_LENGTH_ETHERNET])
        support_prism(ethernet_prism_width + RPI_WIDTH_USB + TOLERANCE*2, RPID_HEIGHT - RPI_HEIGHT_ETHERNET);
    
    // usb support prism
    /*translate([RPI_POSITIONING[0] + ethernet_prism_width, 0, RPI_POSITIONING[2] - RPI_LENGTH_ETHERNET])
        support_prism(RPI_WIDTH_USB + TOLERANCE*2, RPID_HEIGHT - RPI_HEIGHT_USB1);*/
}

module shell_cap() {
    translate([SHELL_WIDTH + SHELL_THICKNESS*4, 0, 0]) {
        rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_THICKNESS], 5, -1);
        translate([SHELL_THICKNESS/2, SHELL_THICKNESS/2, 0])
        rounded_cube([SHELL_WIDTH-SHELL_THICKNESS,
                      SHELL_WIDTH-SHELL_THICKNESS,
                      SHELL_THICKNESS*2], 5, -1);
    }
}

supports();
shell();
shell_cap();


translate([0, RPID_HEIGHT, 0])
translate(RPI_POSITIONING)
    rpid();
