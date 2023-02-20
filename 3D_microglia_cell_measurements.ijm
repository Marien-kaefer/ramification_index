/*
Macro to identify fluorescently labelled objects within a tissue and measure intensity parameters, area fraction and ramification index of objects.

												- Written by Marie Held [mheldb@liverpool.ac.uk] January 2023
												  Liverpool CCI (https://cci.liverpool.ac.uk/)
________________________________________________________________________________________________________________________

BSD 2-Clause License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

*/

#@ String (label = "Channel to process", value = 2, persist=true) channelNumber
#@ String (label = "Minimum cell size (micron^3) for ramification index calculation", value = 750, persist=true) minCellSize
#@ String (label = "Minimum object size (micron^3) for intensity and area fraction measurement", value = 100, persist=true) minObjectSize

start = getTime(); 


// once the binary mask of a segmented image has been generated/opened, select it and hit [Run] at the bottom of the script editor. 
originalTitle = getTitle(); //get image title
getDimensions(width, height, channels, slices, frames);
originalTitleWithoutExtension = file_name_remove_extension(originalTitle); //remove extension from image title
directory_path = getDirectory("image");	//get directory path of image and use that later as direcoty for output files
print(TimeStamp() + ": Processing file " + originalTitleWithoutExtension + " located in " + directory_path ); 
labelled_mask = "labelled mask"; 

duplicateTitle = pre_processing(originalTitle, channelNumber, slices, directory_path, originalTitleWithoutExtension); 
//area_fraction(directory_path, originalTitleWithoutExtension, duplicateTitle, minObjectSize);
//intensity_measurements(directory_path, originalTitleWithoutExtension, duplicateTitle, channelNumber);
ramification_index_calculation(directory_path, originalTitleWithoutExtension, duplicateTitle, minObjectSize, minCellSize); 
visualisation(labelled_mask, originalTitleWithoutExtension, directory_path);
//clean_up();

//let user know the process has finished
stop = getTime(); 
duration = stop - start;
duration_String = duration_conversion(duration);
print("The file processing took " + duration_conversion(duration));
print(TimeStamp() + ": Processing of [" + originalTitle + "] complete.");
beep();

function pre_processing(originalTitle, channelNumber, slices, directory_path, originalTitleWithoutExtension){
	selectWindow(originalTitle); 
	//run("Z Project...", "projection=[Max Intensity]");
	setSlice(channelNumber);
	run("Duplicate...", "duplicate channels=2");
	run("Grays");
	duplicateTitle = getTitle();
	
	// https://imagej.net/plugins/clahe
	// CLAHE parameters
	blocksize = 90; //127
	histogram_bins = 127;  //256
	maximum_slope = 3;
	mask = "*None*";
	fast = true;
	process_as_composite = true;
	CLAHE_contrast_enhancement(blocksize, histogram_bins, maximum_slope, mask, fast, process_as_composite);
	//run("Enhance Local Contrast (CLAHE)", "blocksize=90 histogram=127 maximum=3 mask=*None*");
	
	run("Median...", "radius=1 stack");
	setSlice(slices/2); 
	//run("Threshold...");
	setAutoThreshold("Li dark no-reset");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Li background=Dark black create");
	//run("Erode", "stack");
	mask_title = getTitle();
	saveAs("TIFF", directory_path + File.separator + originalTitleWithoutExtension + "-mask.tif");
	rename(mask_title); 
	print("Finished preprocesing and saved " + directory_path + File.separator + originalTitleWithoutExtension + "-mask.tif");
	return mask_title;
}

function CLAHE_contrast_enhancement(blocksize, histogram_bins, maximum_slope, mask, fast, process_as_composite){
	//from http://stefischer.de/2019/06/12/apply-clahe-filter-on-a-stack-in-fiji/
	blocksize = 90; //127
	histogram_bins = 127;  //256
	maximum_slope = 3;
	mask = "*None*";
	fast = true;
	process_as_composite = true;
	 
	getDimensions( width, height, channels, slices, frames );
	isComposite = channels > 1;
	parameters =
	  "blocksize=" + blocksize +
	  " histogram=" + histogram_bins +
	  " maximum=" + maximum_slope +
	  " mask=" + mask;
	if ( fast )
	  parameters += " fast_(less_accurate)";
	if ( isComposite && process_as_composite ) {
	  parameters += " process_as_composite";
	  channels = 1;
	}
	   
	for ( f=1; f<=frames; f++ ) {
	  Stack.setFrame( f );
	  for ( s=1; s<=slices; s++ ) {
	    Stack.setSlice( s );
	    for ( c=1; c<=channels; c++ ) {
	      Stack.setChannel( c );
	      run( "Enhance Local Contrast (CLAHE)", parameters );
	    }
	  }
	}
}


function area_fraction(directory_path, originalTitleWithoutExtension, duplicateTitle, minObjectSize){
	print("Area fraction measurement");
	selectWindow(duplicateTitle);
	run("Analyze Particles...", "size=" + minObjectSize + "-Infinity clear display summarize add");
	//save ROI set for future reference and accountability purposes
	roiManager("Save", directory_path + File.separator + originalTitleWithoutExtension + "-area-fraction-intensity-ROISet.zip");
	selectWindow("Summary");
	saveAs("Results", directory_path + File.separator + originalTitleWithoutExtension + "-Summary_results.csv");
	close(originalTitleWithoutExtension + "-Summary_results.csv");
	print("Finished area fraction"); 
}

function intensity_measurements(directory_path, originalTitleWithoutExtension, duplicateTitle, channelNumber){
	print("Area fraction measurement");
	selectWindow(originalTitle);
	run("Subtract Background...", "rolling=5 stack");
	run("Z Project...", "projection=[Sum Slices]");
	setSlice(channelNumber);
	run("Set Measurements...", "area mean standard modal min integrated median display redirect=None decimal=3");
	roiManager("multi-measure");
	saveAs("Results", directory_path + File.separator + originalTitleWithoutExtension + "-Measurement_results.csv");
	roiManager("Deselect");
	roiManager("reset");
	run("Clear Results");
	print("Finished intensity measurements.");
}

function ramification_index_calculation(directory_path, originalTitleWithoutExtension, duplicateTitle, minObjectSize, minCellSize){
	print("Ramification index measurements.");
	print("Identifying objects. This might take a little while. :) Check the status bar in the main Fiji window."); 
	run("3D OC Options", "volume surface dots_size=5 font_size=10 show_numbers white_numbers store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
	//run("3D Objects Counter", "threshold=128 slice=74 min.=" + minCellSize + " max.=Infinity objects statistics summary");
	run("3D Objects Counter", "threshold=128 slice=74 min.=" + minCellSize + " max.=99999999999999999999 objects");
	rename(labelled_mask); 
	run("glasbey_on_dark");

	print("Generating convex hulls. This could take a long while... :( ............"); 
	run("3D Manager Options", "volume surface convex_hull integrated_density mean_grey_value std_dev_grey_value mode_grey_value minimum_grey_value maximum_grey_value objects distance_between_centers=0 distance_max_contact=1.80 drawing=Contour");
	selectWindow(labelled_mask); 

	run("3D Manager");
	Ext.Manager3D_AddImage();
	Ext.Manager3D_SelectAll();
	Ext.Manager3D_Measure();
	
/*	
	// connected component analysis, i.e. identify objects and assign unique identifiers
	selectWindow(duplicateTitle);
	run("Analyze Particles...", "size=" + minCellSize + "-Infinity exclude display add");  //apply appropriate minimum size filter in µm^2
	
	//save ROI set for future reference and accountability purposes
	roiManager("Save", directory_path + File.separator + originalTitleWithoutExtension + "-cell-ROIs.zip");
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
		roiManager("Select", i);
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
	saveAs("Results", directory_path + File.separator + originalTitleWithoutExtension + "-Ramification_results.csv");
	roiManager("reset");
	roiManager("Deselect");
	
*/
	print("Finished ramification index calculation");
}

function visualisation(labelled_mask, originalTitleWithoutExtension, directory_path){
	selectWindow(labelled_mask); 
	run("3D Project...", "projection=[Mean Value] axis=Y-Axis slice=0.19 initial=0 total=360 rotation=10 lower=1 upper=255 opacity=0 surface=100 interior=50");
	run("Animated Gif ... ", "name=[Projections of labelled] set_global_lookup_table_options=[Load from Current Image] optional=[] image=[No Disposal] set=125 number=0 transparency=[No Transparency] red=0 green=0 blue=0 index=0 filename=[" + directory_path + File.separator + originalTitleWithoutExtension + "3D-animation.gif]");
	//run("Animated Gif ... ", "name=[Projections of labelled] set_global_lookup_table_options=[Load from Current Image] optional=[] image=[No Disposal] set=125 number=0 transparency=[No Transparency] red=0 green=0 blue=0 index=0 filename=[Y:/private/Marie/Image Analysis/2023-01-09-MICHAEL-Cord-circumf-perimeter-ratification-index/playground/filename.gif]");
	print("Finished preprocesing and saved " + directory_path + File.separator + originalTitleWithoutExtension + "-mask.tif");
}

function clean_up(){
	//clean up: close results window, reset ROI Manager, close image window
	run("Close");
	roiManager("reset");
	close("*"); 
}

function file_name_remove_extension(originalTitle){
	dotIndex = lastIndexOf(originalTitle, "." ); 
	file_name_without_extension = substring(originalTitle, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}

// set up time string for print statements
function TimeStamp(){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	month = month + 1;
	TimeString ="["+year+"-";
	if (month<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+month + "-";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth + " --- ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second + "]";
	return TimeString;
}

//convert time from ms to more appropriate time unit
function duration_conversion(duration){
	if (duration < 1000){
		duration_String = duration + " ms";
	} 
	else if (duration <60000){
		duration = duration / 1000;
		duration_String = d2s(duration, 0) + " s";
	}
	else if (duration <3600000){
		duration = duration / 60000;
		duration_String = d2s(duration, 1) +  "min";
	}
	else if (duration <86400000){
		duration = duration / 3600000;
		duration_String = d2s(duration, 0) + " hr";
	}
	else if (duration <604800000){
		duration = duration / 86400000;
		duration_String = d2s(duration, 0) + " d";
	}
	//print("Duration string: " + duration_String);	
	return duration_String;
}
