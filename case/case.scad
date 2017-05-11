RPI_LENGTH = 85;
RPI_WIDTH = 56;
RPI_HEIGHT = 5;

DISPLAY_HEIGHT = 5;
DISPLAY_PIN_HEIGHT = 14;

RPID_HEIGHT = RPI_HEIGHT + DISPLAY_PIN_HEIGHT + DISPLAY_HEIGHT;

SHELL_HEIGHT = 220;
SHELL_WIDTH = 100;
SHELL_THICKNESS = 5;

RPI_POSITIONING = [SHELL_WIDTH / 2 - RPI_WIDTH/2,
                       0,
                       SHELL_HEIGHT/2 - RPI_HEIGHT/2];

//translate([0,0,RPI_LENGTH])
//rotate([90,90,0])

module rpi_with_display() {
    import("raspberry_pi_Bplus.STL", convexity=10);
    
    translate([0, 0, RPI_HEIGHT+DISPLAY_PIN_HEIGHT])
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
            rounded_cube([SHELL_WIDTH, SHELL_WIDTH, SHELL_HEIGHT], 5, SHELL_THICKNESS);
        }
        
        color("red") 
            translate([0, -RPID_HEIGHT, 0])
            translate(RPI_POSITIONING)
            cube([RPI_WIDTH, RPID_HEIGHT*2, RPI_LENGTH]);
    }
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

shell();
shell_cap();
translate([0, RPID_HEIGHT, 0])
translate(RPI_POSITIONING)
    rpid();
