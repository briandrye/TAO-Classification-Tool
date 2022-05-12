# TAO-Classification-Tool

Classify Tree Approximate Objects (TAO) as live/dead. 

## Copy data files to local computer  

### Shapefiles (.shp)  
copy folder that contains the TAO polygons and high points 
note: the .shp files can be in nested folders

### Imagery files  (.tif)
copy folder that contains imagery files 
note: the .tif files can be in nested folders  

## Configuration

install RStudio  
install shiny package  

Open ui.R and server.R in RStudio  
Choose "Run Application" in RStudio  

## Application: Step 1 - Preprocessing
Enter the sample size (Example: 300)  
Enter the path to the folder containing the .shp files  
Enter the path to the folder containing the .tif files  
Create a folder for the output files (cropped images and mortality.csv)  
Enter the output folder path  
Choose a margin (20 is the default)  
Click "Preprocess Imagery" button  
(this will create small .png files for each TAO polygon and create mortality.csv)  

## Application: Step 2 - Classification  
Click "Load CSV" button  
(the first image 1.png should be displayed)  
Use the Live/Dead buttons to classify the TAO Polygon  
(mortality.csv is updated/saved as each Polygon is classified)  




