setSlice(1); 
run("Green");
run("Next Slice [>]");
run("Red");
run("Next Slice [>]");
run("Cyan");
run("Next Slice [>]");
run("Yellow");
Stack.setActiveChannels("0110");

Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");

run("Z Project...", "projection=[Max Intensity]");
resetMinAndMax();
run("Next Slice [>]");
run("Enhance Contrast", "saturated=0.35");
run("Next Slice [>]");
run("Enhance Contrast", "saturated=0.35");
run("Next Slice [>]");
resetMinAndMax();
Stack.setActiveChannels("0110");

