/*
Macro to calculate the ramification index of objects in a binary image. For definition of ramification index see here (https://www.mdpi.com/2073-4409/11/11/1723): 
"the ramification index is defined as the ratio of the cell area (Ac) and the projection area (Ap)."

												- Written by Marie Held [mheldb@liverpool.ac.uk] January 2023
												  Liverpool CCI (https://cci.liverpool.ac.uk/)
________________________________________________________________________________________________________________________

BSD 2-Clause License

Copyright (c) [2022], [Marie Held {mheldb@liverpool.ac.uk}, Image Analyst Liverpool CCI (https://cci.liverpool.ac.uk/)]

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

*/


// once the binary mask of a segmented image has been generated/opened, select it and hit [Run] at the bottom of the script editor. 
originalTitle = getTitle(); //get image title
originalTitleWithoutExtension = file_name_remove_extension(originalTitle); //remove extension from image title
direcory_path = getDirectory("image");	//get directory path of image and use that later as direcoty for output files

// connected component analysis, i.e. identify objects and assign unique identifiers
run("Analyze Particles...", "size=2-Infinity display exclude summarize add");  //apply appropriate minimum size filter in µm^2

//save ROI set for future reference and accountability purposes
roiManager("Save", direcory_path + File.separator + originalTitleWithoutExtension + "-ROISet.zip");
//specify which parameters to measure
run("Set Measurements...", "area redirect=None decimal=3");

// count number of ROIs and specify length of result lists
ROI_count = roiManager("count");
//print("number of ROIs: " + ROI_count); 
cell_area = newArray(ROI_count);
projection_area = newArray(ROI_count);
ramification_index = newArray(ROI_count);

// loop through each ROI and measure the area then generate and measure the area of the convex hull, calculate the ramification index as cell area divided by convex hull area
for (i = 0; i < ROI_count; i++) {
	roiManager("Select", i);
	run("Measure");
	cell_area[i] = getResult("Area", 0);
	run("Convex Hull");
	run("Measure");
	projection_area[i] = getResult("Area", 1);
	run("Clear Results");
	ramification_index[i] = cell_area[i] / projection_area[i]; 
}

//write results into a new results window 
for (i = 0; i < ROI_count; i++) {
	setResult("Object Area", i, cell_area[i]);
	setResult("Object Projection Area", i, projection_area[i]);
	setResult("Ramification Index", i, ramification_index[i]);  
}

// save results with file name including original file name
selectWindow("Results");
saveAs("Results", direcory_path + File.separator + originalTitleWithoutExtension + "-Ramification_results.csv");

//clean up: close results window, reset ROI Manager, close image window
run("Close");
roiManager("reset");
close("*"); 

//let user know the process has finished
print("Processing of [" + originalTitle + "] finished.");
beep();



function file_name_remove_extension(originalTitle){
	dotIndex = lastIndexOf(originalTitle, "." ); 
	file_name_without_extension = substring(originalTitle, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}