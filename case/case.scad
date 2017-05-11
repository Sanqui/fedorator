HIDE_SHELL = false;
SPLIT_SHELL = true;
SPLIT_SHELL_UPSIDE_DOWN = true;
$fn=80;

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

DISPLAY_MARGIN_BOTTOM = 2.0;
DISPLAY_MARGIN_SIDE = 2.0;
DISPLAY_MARGIN_TOP = 6;

RPID_HEIGHT = RPI_HEIGHT + DISPLAY_PIN_HEIGHT + DISPLAY_HEIGHT;

USB_PORT_WIDTH = 15;
USB_PORT_HEIGHT = 8;
USB_PORT_LENGTH = 10;
USB_PORT_BOTTOM_EXTRA = 2;
USB_PORT_SIDE_EXTRA = 1;
USB_PORT_CONNECTOR_LENGTH = 40;

USB_CABLE_DIAMETER = 5;

SHELL_HEIGHT = 157;
SHELL_WIDTH = 80;
SHELL_THICKNESS = 5;

BACK_SUPPORT_LENGTH = SHELL_WIDTH/8;
CABLE_HOLE_WIDTH = 20;
USB_PORT_SUPPORT_CABLE_LENGTH = (SHELL_WIDTH - USB_PORT_CONNECTOR_LENGTH) / 2;
USB_PORT_SUPPORT_PILLAR_SIZE = USB_PORT_LENGTH;

RPI_POSITIONING = [SHELL_WIDTH / 2 - (RPI_WIDTH_FULL)/2,
                       SHELL_THICKNESS,
                       SHELL_HEIGHT/2 - RPI_LENGTH_FULL/5];

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
    if (!HIDE_SHELL) {
        difference() {
            union() {
                // shell
                rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_HEIGHT], SHELL_THICKNESS, SHELL_THICKNESS);
                
                // cap
                translate([0, 0, SHELL_HEIGHT - SHELL_THICKNESS])
                    rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_THICKNESS], SHELL_THICKNESS, -1);
            }
            
            color("red")
            union() {
                // hole for display
                translate([0, -RPID_HEIGHT, 0])
                translate(RPI_POSITIONING)
                translate([DISPLAY_MARGIN_SIDE, 0, DISPLAY_MARGIN_BOTTOM])
                translate([RPI_LEFT_PORTS_WIDTH, 0, 0])
                    cube([RPI_WIDTH+TOLERANCE - DISPLAY_MARGIN_SIDE,
                          RPID_HEIGHT*2,
                          RPI_LENGTH+TOLERANCE - DISPLAY_MARGIN_TOP]);
                
                // hole for power cable in the back
                translate([SHELL_WIDTH*0.1, SHELL_WIDTH, SHELL_THICKNESS*4])
                    cube([CABLE_HOLE_WIDTH, CABLE_HOLE_WIDTH, CABLE_HOLE_WIDTH]);
        
                // holes for usb ports
                for (i = [1, NUM_USB_PORTS]) {
                    translate([i*SHELL_WIDTH/(NUM_USB_PORTS+1) - USB_PORT_WIDTH/2, -USB_PORT_LENGTH, USB_PORT_Z])
                        color("blue") cube([USB_PORT_WIDTH, USB_PORT_LENGTH*2, USB_PORT_HEIGHT]);
                }
            }
        }
    }
}

module support_pillar() {
    cube([(SHELL_WIDTH - RPI_WIDTH_FULL)/2,
          RPI_POSITIONING[1] + RPID_HEIGHT,
          RPI_POSITIONING[2] + RPI_LENGTH/2]);
}

module support_prism(l, w) {
    translate([0, w, 0])
    prism(l, -w, -PRISM_SUPPORT_HEIGHT );
}

module back_support_prism(offset) {
    translate([offset, RPI_POSITIONING[1] + BACK_SUPPORT_LENGTH + RPID_HEIGHT, 0])
        prism((SHELL_WIDTH - RPI_WIDTH_FULL)/2, -BACK_SUPPORT_LENGTH, -PRISM_SUPPORT_HEIGHT );
}

module back_support(height) {
    translate([0, 0, height]) {
        translate([0, RPI_POSITIONING[1] + RPID_HEIGHT, 0])
        cube([SHELL_WIDTH,
              BACK_SUPPORT_LENGTH,
              BACK_SUPPORT_LENGTH]);

        back_support_prism(0);
        back_support_prism(RPI_POSITIONING[0] + RPI_WIDTH_FULL );
    }
}

module usb_port_support_pillar() {
    cube([USB_PORT_WIDTH + USB_PORT_SIDE_EXTRA*2, USB_PORT_SUPPORT_PILLAR_SIZE, USB_PORT_Z - USB_PORT_HEIGHT - USB_PORT_BOTTOM_EXTRA]);
}

module usb_cable(length) {
    rotate([-90, 0, 0])
    cylinder(h=length, r=USB_CABLE_DIAMETER/2);
}

module usb_port_support() {
    difference() {
        union() {
            base_support_height = USB_PORT_Z - USB_PORT_HEIGHT - USB_PORT_BOTTOM_EXTRA;
            translate([0, 0, base_support_height]) {
                cube([USB_PORT_WIDTH + USB_PORT_SIDE_EXTRA*2, USB_PORT_CONNECTOR_LENGTH + 4, USB_PORT_HEIGHT]);
                
                translate([0, USB_PORT_CONNECTOR_LENGTH + 4, 0])
                    cube([USB_PORT_WIDTH + USB_PORT_SIDE_EXTRA*2,
                        USB_PORT_SUPPORT_CABLE_LENGTH, USB_PORT_HEIGHT + USB_CABLE_DIAMETER]);
            }
            
            translate([0, 0, 0])
                usb_port_support_pillar();
            translate([0, USB_PORT_CONNECTOR_LENGTH + 4 + USB_PORT_SUPPORT_CABLE_LENGTH - USB_PORT_SUPPORT_PILLAR_SIZE, 0])
                usb_port_support_pillar();
        }
        
        translate([(USB_PORT_WIDTH + USB_PORT_SIDE_EXTRA*2)/2, 0, USB_PORT_Z + USB_PORT_BOTTOM_EXTRA])
            usb_cable(USB_PORT_CONNECTOR_LENGTH + 4 + USB_PORT_SUPPORT_CABLE_LENGTH);
    }
}

module supports() {
    // floor
    rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_THICKNESS], SHELL_THICKNESS, -1);
    
    // raised border to hold the shell in
    translate([SHELL_THICKNESS, SHELL_THICKNESS, 0])
    rounded_cube([SHELL_WIDTH-SHELL_THICKNESS*2, SHELL_WIDTH-SHELL_THICKNESS*2, SHELL_THICKNESS*4], SHELL_THICKNESS*2, 4);
    translate([0, 0, 0])
        support_pillar();
    translate([RPI_POSITIONING[0] + RPI_WIDTH_FULL , 0, 0])
        support_pillar();
    
    // back support
    back_support(RPI_POSITIONING[2]);
    back_support(RPI_POSITIONING[2] + RPI_LENGTH/2);
    
    // ethernet support prism
    ethernet_prism_width = RPI_WIDTH_ETHERNET + RPI_LEFT_PORTS_WIDTH;
    translate([RPI_POSITIONING[0], 0, RPI_POSITIONING[2] - RPI_LENGTH_ETHERNET])
        support_prism(ethernet_prism_width + RPI_WIDTH_USB + TOLERANCE*2, RPID_HEIGHT - RPI_HEIGHT_ETHERNET);
    
    // usb support prism (dropped in favor of a single prism)
    /*translate([RPI_POSITIONING[0] + ethernet_prism_width, 0, RPI_POSITIONING[2] - RPI_LENGTH_ETHERNET])
        support_prism(RPI_WIDTH_USB + TOLERANCE*2, RPID_HEIGHT - RPI_HEIGHT_USB1);*/
    
    // supports for each port
    for (i = [1, NUM_USB_PORTS]) {
        translate([i*SHELL_WIDTH/(NUM_USB_PORTS+1) - USB_PORT_WIDTH/2, 0, 0])
            usb_port_support();
    }
    
    // connect pillars for extra stability
    cube([SHELL_WIDTH,
          USB_PORT_SUPPORT_PILLAR_SIZE,
          USB_PORT_Z]);
    
}

/*module shell_cap() {
    translate([SHELL_WIDTH + SHELL_THICKNESS*4, 0, 0]) {
        rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_THICKNESS], 5, -1);
        translate([SHELL_THICKNESS/2, SHELL_THICKNESS/2, 0])
        rounded_cube([SHELL_WIDTH-SHELL_THICKNESS,
                      SHELL_WIDTH-SHELL_THICKNESS,
                      SHELL_THICKNESS*2], 5, -1);
    }
}*/

module split_bottom(){
    difference(){
        supports();
        shell();
    }
}

module split_top(){
    difference(){
        shell();
        supports();
    }
}

module main() {
    if (SPLIT_SHELL) {
        split_bottom();
        
        if (SPLIT_SHELL_UPSIDE_DOWN) {
            translate([SHELL_WIDTH * 2.2, 0, SHELL_HEIGHT])    
            rotate([0, 180, 0]) split_top();
        } else {
            translate([SHELL_WIDTH * 1.2, 0, 0])
            rotate([0, 0, 0]) split_top();
        }
    } else {
        supports();
        shell();
    }
}
//shell_cap();

difference(){
    main();
    /*color("red") translate([-5, -5, 0]) cube([200, 100, 95]);
    color("red") translate([-5, -5, 120]) cube([100, 100, 100]);
    color("red") translate([90, 1, 105]) cube([100, 100, 200]);
    color("red") translate([90, -5, 190]) cube([100, 100, 200]);
    */
}



translate([0, RPID_HEIGHT, 0])
translate(RPI_POSITIONING)
    rpid();

//translate([100, 100, 100])
//import("fedora.dxf");