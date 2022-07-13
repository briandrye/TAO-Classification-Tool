# TAO-Classification-Tool

Classify Tree Approximate Objects (TAO) as live/dead, etc.

Note: to test the classifier UI, you can skip steps 1 and 2 by using the sample output data in the sampleStep2data.zip file. 
Unzip the file, then skip to Step 3. 
## Copy data files to local computer  

### Shapefiles (.shp)  
copy folder from network drive that contains the TAO polygons and high points 
note: the .shp files can be in nested folders  
Example: Z:\01_LiDAR_data\Processed_FUSION\California\SSARR_2020_rerun\Segments_0p75METERS => D:\Segments_0p75METERS

### Imagery files (.tif)
copy folder from network drive that contains imagery files 
note: the .tif files can be in nested folders  
Example: NAIP_2020\NAIP_4Band_2020\imagery => D:\NAIP_4Band_2020\imagery

### Elevation file (.img)
copy file from network drive that contains raster of elevation info  
Example: Z:\01_LiDAR_data\Processed_FUSION\California\SSARR_2020_rerun\TopoMetrics_30METERS\topo_elevation_15M_30METERS.img => D:\TopoMetrics_30METERS/topo_elevation_15M_30METERS.img  

## Configuration
install RStudio  
install packages: shiny, stringr, terra  
clone repository to local machine 


## Step 1 - Create csv files with Intensity and Elevation information for each high point  
note 1: this step make take a few days to complete (10000 shape files => about 3 days)
note 2: you may not have to do this. I already ran it against a local copy of  
Z:\01_LiDAR_data\Processed_FUSION\California\SSARR_2020_rerun\Segments_0p75METERS  

Open step1.R in RStudio  
Set the following (to the locations on your local machine:  
shapeFolder = "D:/Segments_0p75METERS/"  
elevationFile = "D:/TopoMetrics_30METERS/topo_elevation_15M_30METERS.img"  
outputFolder = "D:/step1/"  
Run the script
(you should now have a bunch of .csv files in the outputFolder)  

## Step 2 - Sample polygons by Intensity/Elevation, save mortality.csv and .png files

Open step2.R in RStudio  
Set the following (to the locations on your local machine:  
inputFolder = "D:/step1/"  
imageryFolder = "C:/Users/bdrye/Downloads/NAIP_2020/NAIP_4Band_2020/imagery"  
shapeFolder = "D:/Segments_0p75METERS/"  
outputFolder = "D:/step2/"  
margin = 30  
desiredSampleSize = 640  
binCount = 8  
Run the script  
(you now have mortality.csv and .png files for each polygon that was sampled)  
note: mortality.csv also contains the Intensity and Elevation information  


## Step 3 - Classification via Shiny Application  
Open ui.R and server.R in RStudio  
Choose "Run Application" in RStudio  
Update the Input Folder path to match the outputFolder from Step 2 (D:/step2/)  
Click "Load mortality.csv" button  
(the first unclassified image should be displayed)  
Use the dropdown and radio buttons to classify the TAO Polygon  
Click "Update mortality.csv"  
(mortality.csv is updated/saved with the classification information)  


## Notes  
Polygons are subsetted by removing the bottom and top 1 percent (based on Intensity).  
If you know which image files contain the polygons you can improve the performance of Step 2 by excluding other image files.  
Some polygons do not have elevations, they are excluded. Reason: elevation raster has jagged edges.  
When cropping, if the crop extent is invalid, the polygon is discarded.  
Rows in mortality.csv are shuffled at the end of Step 2. 






