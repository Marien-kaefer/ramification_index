# microglia_cell_measurements.ijm
This works for a multichannel z-stack containing fluorescently stained microglia cells. Only one channel is processed and can be chosen via a pop up dialog. The processing steps are as follows: 

1. Open full dataset, raw input file (use virtual stack if too big for RAM)

2. Pre-processing 
	- Maximum intensity projection
	- duplicate
	- apply Grays LUT
	- enhance contrast: CLAHE (https://imagej.net/plugins/clahe)
	- Threshold using Li
	- save mask in input file directory {originalFileName-mask.tif}
	
3. Area Fraction measurement
	- duplicate mask
	- Analyze particles: size 2-Inf µm^2; summarize, add to manager [the size filter should exclude objcts caused by background/noise but still include cell segments; adjustable via initial user dialog] 
	- save summary table (containing %Area = area fraction based on whole FOV) and ROI set in input file directory: {originalFileName-Summary_results.csv} & {originalFileName-area-fraction-intensity-ROISet.zip}
	
4. Intensity measurements
	- for original image, substract background: rolling ball = 5, process whole stack
	- Sum Slices projection
	- activate all intensity-based parameters: area mean standard modal min integrated median display
	- Measure all ROIs 
	- save results in input file directory {originalFileName-Measurement_results.csv}
	- clear ROI manager
	
5. Ramification index measurements
	- select original mask
	- Analyze particles: size 35-Inf µm^2; summarize, exclude from edges, add to manager [the size filter should include only objects that are large enough to be whole cells; adjustable via initial user dialog] 
	- save ROI set in input file directory: {originalFileName-cell-ROIs.zip}
	- set measurement parameters to area only
	- loop through all ROIs: 
		* measure area
		* create convex hull
		* measure area of convex hull
		* calculare ramification index: area / convex hull area
	- collate all results in a results table and save table in input file directory	{originalFileName-Ramification_results.csv}

6. Clean up
	- close results file
	- reset ROI manager
	- close all image windows

# ramification_index.ijm

The starting point is a generated segmentation mask. Once the binary mask has been generated/opened, select it and hit [Run] at the bottom of the script editor. 
