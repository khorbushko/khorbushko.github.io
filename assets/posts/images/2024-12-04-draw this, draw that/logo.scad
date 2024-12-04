
//Logo();

module Logo() {
    
    size = 50;
    
    difference() {
        
    translate([0, 20, 50]) 
        rotate([0, 90, 0])  
        linear_extrude(30) circle(size*2);
    
    translate([0, 20, 50]) 
        rotate([0, 90, 0])  
        linear_extrude(30) circle(size*2*0.8);
    }
    
    
    translate([0, 50, 0]) cube([30,30,100]);
    translate([0, 0, 35]) cube([30,80,30]);
   
    
    cube([30,30,100]);
    
    rotate([45, 0, 0]) 
        translate([0, 25, 25]) cube([30,30,60]);
    
    rotate([-45, 0, 0]) 
        translate([0, -50, -25]) cube([30,30,60]);
}

// Parameters
circle_thickness = 10;  // Thickness of the circle
letter_height = 40;    // Height of the letters
letter_depth = 5;      // Depth of the letters
font_size = 50;        // Font size for the letters
circle_diameter = font_size*2; // Diameter of the circle
font_style = "Impact";  // Font style
letter_spacing = 0.5;  // Adjust spacing between letters

// Main model
module logo() {
    

    rotate([0, 90, 0]) 
    difference() {
        cylinder(d = circle_diameter, h = circle_thickness, center = true);
        cylinder(d = circle_diameter - circle_thickness * 2, h = circle_thickness, center = true);
    }

    // Letters "HK" with adjusted alignment

    rotate([90, 00, 0]) 
        rotate([0, 90, 0]) 
        translate([-font_size/4, 0, -circle_thickness/2])
            linear_extrude(height = letter_depth)
                text("H K", 
                    size = font_size, 
                    valign = "center", 
                    halign = "center", 
                    spacing = letter_spacing, 
                    font = font_style);
}

// Render logo
logo();
