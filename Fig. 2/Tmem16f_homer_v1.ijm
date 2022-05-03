/* Macro written by Yajing Xu, ISMMS August 2021
*/
	
	dir1 = getDirectory("Choose Source Directory "); //select an input folder
 	dir2 = getDirectory("Choose a folder to save to"); //select an output folder. 
 	list = getFileList(dir1); //make a list of the filenames
 	setBatchMode(true); //turn on batch mode to run in the background - RAM keeps filling up!

	run("3D Manager Options", "volume distance_between_centers=10 distance_max_contact=1.80"); //set 3D manager to only measure volumes


for (k=0; k<list.length; k++) { 
 	showProgress(k+1, list.length);
 	filename = dir1 + list[k];
	open(filename);	
	run("Bio-Formats", "open=[filename] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

	//setMinAndMax(0, 65535); //set bit depth for homogeneous brightness in deconv images
	Imagename = File.nameWithoutExtension;//record image name for saving results

//make copy to merge at the end
	run("Duplicate...", "title=Orig duplicate channels=7-9");
	selectWindow("Orig");
	run("Duplicate...", "title=THY1 duplicate channels=1");
	run("8-bit");
	run("Duplicate...", "title=THY1_2 duplicate");
	selectWindow("Orig");
	run("Duplicate...", "title=HOMER duplicate channels=2");
	run("8-bit");
	run("Duplicate...", "title=HOMER_2 duplicate");
	selectWindow("Orig");
	run("Duplicate...", "title=VGLUT1 duplicate channels=3");
	run("8-bit");
	run("Duplicate...", "title=VGLUT1_2 duplicate");


//preprocess Thy1
	selectWindow("THY1");
	run("Duplicate...", "title=thy1 duplicate");
	run("Subtract Background...", "rolling=20 stack");
	run("Median...", "radius=1 stack");
	setAutoThreshold("Triangle dark stack"); //moments worked well for most apart from FnAN 4
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Triangle background=Dark");	
	rename("thy1mask");

//preprocess Homer
	selectWindow("HOMER");
	run("Duplicate...", "title=homer duplicate");
	run("Subtract Background...", "rolling=5 stack");
	run("Median...", "radius=0.5 stack");
	//run("Median 3D...", "x=1 y=1 z=1");
	setAutoThreshold("Moments dark stack"); //moments worked well for most apart from FnAN 4
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Moments background=Dark");	
	rename("homermask");


//preprocess Vglut1
	selectWindow("VGLUT1");
	run("Duplicate...", "title=vglut1 duplicate");
	run("Subtract Background...", "rolling=10 stack");
	run("Median...", "radius=2 stack");
	//run("Median 3D...", "x=1 y=1 z=1");
	setAutoThreshold("Otsu dark stack"); //moments worked well for most apart from FnAN 4
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Dark");
	rename("vglut1mask");
	run("Duplicate...", "title=vglut1mask_dilated duplicate");
	selectWindow("vglut1mask_dilated");
	run("Options...", "iterations=4 count=3 do=Dilate stack");


//Make a binary image of Thy1 overlap with Homer and Vglut1
		imageCalculator("AND create stack", "thy1mask","vglut1mask");
		run("Options...", "iterations=4 count=3 do=Dilate stack");
		rename("vglut1_in_thy1_dilated");
		imageCalculator("AND create stack", "vglut1_in_thy1_dilated","homermask");
		rename("homer+vglut1_in_thy1");

//Make a binary image of Homer and Vglut1 overlap w/o Thy1
		imageCalculator("AND create stack", "homermask","vglut1mask_dilated");
		rename("homer+vglut1");
		
//Run the 3Dmanager to 3D segement homer, save total volume + no. of objects + vol of each object
		selectWindow("homermask");
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+"_Hom_Vol"+Imagename+".csv");
		Ext.Manager3D_CloseResult("M");

		selectWindow("homermask");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_Count(nb);
		print("Number of homer_"+Imagename+" = "+nb);
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+Imagename+"Roi3D.zip");
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		
		Ext.Manager3D_SaveResult("M", dir2+"_Homer_Objects"+Imagename+".csv"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

		
//Run the 3Dmanager to 3D segement vglut1, save total volume + no. of objects + vol of each object
		selectWindow("vglut1mask");
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+"_Vglut1_Vol"+Imagename+".csv");
		Ext.Manager3D_CloseResult("M");

		selectWindow("vglut1mask");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_Count(nb);
		print("Number of vglut1_"+Imagename+" = "+nb);
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+Imagename+"Roi3D.zip");
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		
		Ext.Manager3D_SaveResult("M", dir2+"_Vglut1_Objects"+Imagename+".csv"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");


//Run the 3Dmanager to 3D segement homer+vglut1 synapses, save total volume + no. of objects + vol of each object
		selectWindow("homer+vglut1");
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+"_Syn_Vol"+Imagename+".csv");
		Ext.Manager3D_CloseResult("M");

		selectWindow("homer+vglut1");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_Count(nb);
		print("Number of synapses_"+Imagename+" = "+nb);
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+Imagename+"Roi3D.zip");
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		
		Ext.Manager3D_SaveResult("M", dir2+"_Synapses_Objects"+Imagename+".csv"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

//Run the 3Dmanager to 3D segement homer+vglut1 synapses in thy1, save total volume + no. of objects + vol of each object
		selectWindow("homer+vglut1_in_thy1");
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+"_Syn_Vol_inThy1_"+Imagename+".csv");
		Ext.Manager3D_CloseResult("M");

		selectWindow("homer+vglut1_in_thy1");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_Count(nb);
		print("Number of synapses in Thy1 "+Imagename+" = "+nb);
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(dir2+Imagename+"Roi3D.zip");
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		
		Ext.Manager3D_SaveResult("M", dir2+"_Synapses_Objects_inThy1_"+Imagename+".csv"); // save the results
		Ext.Manager3D_CloseResult("M");
		run("Collect Garbage");

//create composite image to check results

		selectWindow("thy1mask");
		run("Invert LUT");
		selectWindow("homermask");
		run("Invert LUT");
		selectWindow("vglut1mask");
		run("Invert LUT");
		selectWindow("homer+vglut1");
		run("Invert LUT");
		selectWindow("homer+vglut1_in_thy1");
		run("Invert LUT");
		
		run("Merge Channels...", "c1=[THY1] c2=[HOMER] c3=[VGLUT1] c4=[thy1mask] c5=[homermask] c6=[vglut1mask] create");
		Stack.setChannel(1);          
		run("Blue");
		Stack.setChannel(2); 
		run("Cyan");
		Stack.setChannel(3); 
		run("Magenta");
		Stack.setChannel(4); 
		run("Yellow");
		Stack.setChannel(5); 
		run("Red");
		Stack.setChannel(6); 
		run("Green");

		saveAs("tiff", dir2+Imagename+"_Result1");

		run("Merge Channels...", "c1=[THY1_2] c2=[HOMER_2] c3=[VGLUT1_2] c4=[homer+vglut1] c5=[homer+vglut1_in_thy1] create");
		Stack.setChannel(1);          
		run("Blue");
		Stack.setChannel(2); 
		run("Cyan");
		Stack.setChannel(3); 
		run("Magenta");
		Stack.setChannel(4); 
		run("Grays");
		Stack.setChannel(5); 
		run("Yellow");

		saveAs("tiff", dir2+Imagename+"_Result2");
			
// Close all windows and clear RAM
run("Close All");
		run("Collect Garbage");
		setBatchMode(false);
		run("Collect Garbage");
		setBatchMode(true);
}

selectWindow("Log")
saveAs("Text", dir2+"Log with synapse count");

exit("All done " +k+ " images analsyed");
	