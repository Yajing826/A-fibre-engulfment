	dir1 = getDirectory("Choose Source Directory "); //select an input folder
 	dir2 = getDirectory("Choose a folder to save to"); //select an output folder. 
 	list = getFileList(dir1); //make a list of the filenames
 	setBatchMode(true); //turn on batch mode to run in the background - RAM keeps filling up!

	run("3D Manager Options", "volume distance_between_centers=10 distance_max_contact=1.80"); //set 3D manager to only measure volumes


for (k=0; k<list.length; k++) { 
 	showProgress(k+1, list.length);
 	filename = dir1 + list[k];
	open(filename);	
	//setMinAndMax(0, 65535); //set bit depth for homogeneous brightness in deconv images
	Imagename = File.nameWithoutExtension;//record image name for saving results

//make copy to merge at the end
	run("Duplicate...", "title=Orig duplicate");
	selectWindow("Orig");
	run("Duplicate...", "title=VGAT duplicate channels=2");
	//setMinAndMax(0, 65535);

//preprocess VGAT
	selectWindow("VGAT");
	run("Duplicate...", "title=vgat duplicate");
	run("Subtract Background...", "rolling=10 stack");
	run("Median...", "radius=2 stack");
	//run("Median 3D...", "x=1 y=1 z=1");
	setAutoThreshold("Otsu dark stack");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Dark");
	run("Analyze Particles...", "size=10-Infinity pixel circularity=0.00-1.00 show=Masks stack");
	selectWindow("Mask of vgat");
	rename("Filteredvgat");

	
//Run the 3Dmanager to 3D segement VGAT synapses, save total volume + no. of objects + vol of each object
		selectWindow("Filteredvgat");
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Measure();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_SaveResult("M", dir2+"_VGAT_Vol"+Imagename+".csv");
		Ext.Manager3D_CloseResult("M");

		selectWindow("Filteredvgat");
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

			
		selectWindow("Filteredvgat");
		run("Invert LUT");
		run("16-bit");
		
		run("Merge Channels...", "c1=[VGAT] c2=[Filteredvgat] c3=[Filteredvgat-3Dseg] create");
		Stack.setChannel(1);          
		run("Green");
		Stack.setChannel(2); 
		run("Magenta");
		Stack.setChannel(3); 
		run("Grays");


		saveAs("tiff", dir2+Imagename+"_Result");
			
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
	