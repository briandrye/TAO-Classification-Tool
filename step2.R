library(dplyr)
library(terra)
library(stringr)

# step 2
# open high point csv files (created by step 1) that have two new columns: Intensity and Elevation
# take sample stratified by Intensity first, then stratified by Elevation
# look up polygons in image files, make simple data structure for 
# image file => polygonFile, polygons
# foreach image file: 
#   loop through polygonFiles and polygons to make .png files
# shuffle rows 
# output mortality.csv

#############################################
# configure these folder paths and variables: 
#############################################

# input folder (containing .csv files with Intensity and Elevation)
inputFolder = "D:/testSmall/step1/"

# source folder for imagery (.tif files can be in nested folders)
imageryFolder = "C:/Users/bdrye/Downloads/NAIP_2020/NAIP_4Band_2020/imagery"

# source folder for Polygon .shp files 
shapeFolder = "D:/Segments_0p75METERS/"
  
# output folder (where png and mortality.csv will be saved)
outputFolder = "D:/testSmall/step2/"

# margin to use when saving png files
margin = 30

# pick sample size for each bin... 
# example: all polygons are divided into 8 bins based on Intensity
# then within each of those bins, the polygons are divided into 
# 8 bins based on Elevation
# then take an equal number of samples from each bin
desiredSampleSize = 640
binCount = 8
binSampleSizeIntensity = desiredSampleSize/binCount
binSampleSizeElevation = binSampleSizeIntensity/binCount

########################################
# end of user configured paths/variables
########################################


getBlock <- function(filename)
{
  # BLOCK73_C00004_R00003_segments_Polygons.shp
  x <- str_extract(basename(filename),"\\(?BLOCK[0-9,]+\\)?")
  if(is.null(x))
  {
    return(0)
  }
  else
  {
    x <- str_extract(x, "\\(?[0-9,]+\\)?")
    as.numeric(x[1])
  }
}
getColumn <- function(filename)
{
  # BLOCK73_C00004_R00003_segments_Polygons.shp
  x <- str_extract(basename(filename),"\\(?C[0-9,]+\\)?")
  if(is.null(x))
  {
    return(0)
  }
  else
  {
    x <- str_extract(x, "\\(?[0-9,]+\\)?")
    as.numeric(x[1])
  }
}
getRow <- function(filename)
{
  # BLOCK73_C00004_R00003_segments_Polygons.shp
  x <- str_extract(basename(filename),"\\(?R[0-9,]+\\)?")
  if(is.null(x))
  {
    return(0)
  }
  else
  {
    x <- str_extract(x, "\\(?[0-9,]+\\)?")
    as.numeric(x[1])
  }
}
getSubtile <- function(filename)
{
  # BLOCK73_C00004_R00003_S00007_Polygons.shp
  x <- str_extract(basename(filename),"\\(?S[0-9,]+\\)?")
  if(is.null(x))
  {
    return(0)
  }
  else
  {
    x <- str_extract(x, "\\(?[0-9,]+\\)?")
    as.numeric(x[1])
  }
}


set.seed(0)
startTime = Sys.time()
print(startTime)


listOfImageFiles <-
  list.files(
    path = imageryFolder,
    pattern = "\\.tif$",
    full.names = TRUE,
    ignore.case = TRUE,
    recursive = TRUE
  )

listOfHighPointFiles = list.files(path = inputFolder, pattern = "\\HighPoints_IntensityElevation.csv$", full.names = TRUE, ignore.case = TRUE)

listofDf = lapply(listOfHighPointFiles, read.csv)

print("Reading in .csv files done")
print(Sys.time())

combinedDf = bind_rows(listofDf)

# overall summary
# summary(combinedDf)

# get 1% and 99%, remove rows below and above... 
quantiles = quantile(combinedDf$Intensity, c(.01, .99))
combinedDf = combinedDf[combinedDf$Intensity > quantiles["1%"] & combinedDf$Intensity < quantiles["99%"], ]

# create 8 bins (as dataframes)
histInfo = hist(combinedDf$Intensity, breaks = seq(min(combinedDf$Intensity), max(combinedDf$Intensity), length.out = 9)) 
binDfs = split(combinedDf, cut(combinedDf$Intensity, histInfo$breaks, include.lowest=TRUE))

sampledDf = data.frame(matrix(nrow=0, ncol=ncol(combinedDf)))
names(sampledDf) = names(combinedDf)

for(i in 1:length(binDfs))
{
  if(histInfo$counts[i] < binSampleSizeIntensity)
  {
    # use all the rows
    sampleRows = seq(1, histInfo$counts[i])
    print("Intensity bin has fewer than binSampleSizeIntensity... taking all")
    sampledDf = rbind(sampledDf, binDfs[[i]][sampleRows, ])
    next
  }
  else
  {
    # get distribution of Elevations in bin
    histInfoElevation = hist(binDfs[[i]]$Elevation, breaks = seq(min(binDfs[[i]]$Elevation), max(binDfs[[i]]$Elevation), length.out = 9))
    binDfsElevation = split(binDfs[[i]], cut(binDfs[[i]]$Elevation, histInfoElevation$breaks, include.lowest=TRUE))

    for(j in 1:length(binDfsElevation))
    {
      # take 80/8 = 10 samples from each Elevation bin (if possible)
      #hist(binDfsElevation[[j]]$Elevation)
      if(histInfoElevation$counts[j] < binSampleSizeElevation)
      {
        # take all rows
        sampleRows = seq(1, histInfoElevation$counts[j])
        print("Elevation bin has fewer than binSampleSizeElevation... taking all")
      }
      else
      {
        sampleRows = sample(1:nrow(binDfsElevation[[j]]), size=binSampleSizeElevation)
      }
      sampledDf = rbind(sampledDf, binDfsElevation[[j]][sampleRows, ])
    }
  }
}

# sanity check
print(dim(combinedDf))
print(dim(sampledDf))

# sampledDf now contains the sampled polygons
# next, see which image files contain highpoints/polygons

print("sampleDf done")
print(Sys.time())


listOfPolygonFilesInImage = list()

# break sampledDf into a list of dataframes based on PolygonFile
listOfDfs = split(sampledDf, sampledDf$PolygonFile)
polygonFileNames = names(listOfDfs)

for(k in 1:length(polygonFileNames))
{
  # get all rows for this polygon file
  dfForPolygonFile = listOfDfs[[polygonFileNames[k]]]
  # assume basinIds are unique within a tile
  basinIds = dfForPolygonFile$BasinID

  polygonVect = vect(paste0(shapeFolder, polygonFileNames[k]))
  highpointFilename = sub("Polygons.shp", "HighPoints.shp", polygonFileNames[k])
  highPointVector = vect(paste0(shapeFolder, highpointFilename))
  rowsToUse = polygonVect$BasinID %in% basinIds
  sampledPolygonVect = polygonVect[rowsToUse, ]
  sampledHPVect = highPointVector[rowsToUse, ]

  # find highpoints (polygons) in image files...
  highPointsFound = array(0, dim=length(sampledHPVect))
  
  for (i in 1:length(listOfImageFiles))
  {
    # each tif file may have a different CRS... 
    tempSpatRaster = rast(listOfImageFiles[i])
    sampledPolygonVect = project(sampledPolygonVect, tempSpatRaster)
    sampledHPVect = project(sampledHPVect, tempSpatRaster)
    highPoints = geom(sampledHPVect, df=TRUE)
    
    # look for sampled high points inside the image extent
    # note: simple search... just loop through each high point. 
    # if we find all points, quit searching
    # highpoint (polygon) might be in more than one image
    # once found, mark the high point as found
    tempExtent <- ext(tempSpatRaster)
    polygons <- vector()
    intensities <- vector()
    elevations <- vector()
    
    for (j in 1:nrow(highPoints))
    {
#      print(paste("k i j: ", k, ":", i, ":", j))
      # if(k == 1 && i == 469 && j == 11)
      # {
      #   print("break")
      # }
      
      if(highPointsFound[j] == 1)
      {
        next
      }
      if (tempExtent$xmin < highPoints[j, 'x'] &&
          tempExtent$xmax > highPoints[j, 'x'] &&
          tempExtent$ymin < highPoints[j, 'y'] &&
          tempExtent$ymax > highPoints[j, 'y'])
      {
        highPointsFound[j] <- 1
        polygons = append(polygons, dfForPolygonFile[j, "BasinID"])
        intensities = append(intensities, dfForPolygonFile[j, "Intensity"])
        elevations = append(elevations, dfForPolygonFile[j, "Elevation"])
      }
    }
    
    # save list of polygons (BasinIDs) in a list of lists
    # image file index -> list of polygon file names
    # image file index -> list of lists (which BasinIDs in corresponding polygon file)
    if (length(polygons) > 0)
    {
      if(i <= length(listOfPolygonFilesInImage) && length(listOfPolygonFilesInImage[[i]]) == 4)
      {
        listOfPolygonFilesInImage[[i]][[1]] = append(listOfPolygonFilesInImage[[i]][[1]], polygonFileNames[k])
        listOfPolygonFilesInImage[[i]][[2]] = append(listOfPolygonFilesInImage[[i]][[2]], list(polygons))
        listOfPolygonFilesInImage[[i]][[3]] = append(listOfPolygonFilesInImage[[i]][[3]], list(intensities))
        listOfPolygonFilesInImage[[i]][[4]] = append(listOfPolygonFilesInImage[[i]][[4]], list(elevations))
      }
      else
      {
        listOfPolygonFilesInImage[[i]] = list(polygonFileNames[k])
        listOfPolygonFilesInImage[[i]] = append(listOfPolygonFilesInImage[[i]], list(list(polygons)))
        listOfPolygonFilesInImage[[i]] = append(listOfPolygonFilesInImage[[i]], list(list(intensities)))
        listOfPolygonFilesInImage[[i]] = append(listOfPolygonFilesInImage[[i]], list(list(elevations)))
      }

      if(all(highPointsFound == 1))
      {
        #print("all highpoints found.")
        break
      }
    }
  }
}

print("finding polygons in image files done")
print(Sys.time())

# once we know which images contain polygons, open those images 
# and save png files and mortality.csv

# make a dataframe to save as a csv (this csv will be the input file to TAO Classifier)
mortalityDf = data.frame(matrix(nrow=0, ncol=13))
names(mortalityDf) <- c("Block","Column","Row","Subtile","Basin","MortalityStatus","Nadir","Error", "SourceImage","CropImage","Intensity", "Elevation", "NAIPYear")

for(i in 1:length(listOfPolygonFilesInImage))
{
  if(4 == length(listOfPolygonFilesInImage[[i]]))
  {
    print(listOfImageFiles[i])
    imageRast = rast(listOfImageFiles[i])
    
    for(j in 1:length(listOfPolygonFilesInImage[[i]][[1]]))
    {
      polygonFile = listOfPolygonFilesInImage[[i]][[1]][[j]]
      # print(polygonFile)  # Polygon filename
      polygonList = listOfPolygonFilesInImage[[i]][[2]][[j]]
      # print(polygonList)  # list of polygons we want to make images for
      intensityList = listOfPolygonFilesInImage[[i]][[3]][[j]]
      elevationList = listOfPolygonFilesInImage[[i]][[4]][[j]]
      
      # open polygon file, subset by BasinIDs, project... 
      polygonVect = vect(paste0(shapeFolder, polygonFile))
      polygonVect = polygonVect[polygonVect$BasinID %in% polygonList, ]
      polygonVect = project(polygonVect, imageRast)
      
      tempDf = data.frame(matrix(nrow=length(polygonVect), ncol=ncol(mortalityDf)))
      names(tempDf) <- names(mortalityDf)
      
      for (k in 1:length(polygonVect))
      {
        #print(paste("i:j:k", i, j, k))
        tempExtent = ext(polygonVect[k])
        tempExtent$xmin <- tempExtent$xmin - margin
        tempExtent$xmax <- tempExtent$xmax + margin
        tempExtent$ymin <- tempExtent$ymin - margin
        tempExtent$ymax <- tempExtent$ymax + margin
        
        # make sure crop is within imageRast
        imageExtent = ext(imageRast)
        if(tempExtent$xmin < imageExtent$xmin) tempExtent$xmin = imageExtent$xmin
        if(tempExtent$xmax > imageExtent$xmax) tempExtent$xmax = imageExtent$xmax
        if(tempExtent$ymin < imageExtent$ymin) tempExtent$ymin = imageExtent$ymin
        if(tempExtent$ymax > imageExtent$ymax) tempExtent$ymax = imageExtent$ymax
        
        if(tempExtent$xmin > tempExtent$xmax || tempExtent$ymin > tempExtent$ymax)
        {
          print(paste("i:j:k", i, j, k))
          print(polygonFile)
          print(listOfImageFiles[i])
          print("invalid extent... skipping") 
          next
        }
        
        croppedImage <- crop(imageRast, tempExtent)
        
        pngFilename = sub("segments_Polygons.shp", paste0(polygonVect[k]$BasinID, ".png"), polygonFile)
        pngFullPath = paste0(outputFolder, pngFilename)
        png(pngFullPath)
        
        tempPlot <- plotRGB(croppedImage)
        lines(geom(polygonVect[k])[, 'x'],
              geom(polygonVect[k])[, 'y'],
              col = "red")
        dev.off()
        
        # fill in dataframe
        basinIDindex = which(polygonList == polygonVect[k]$BasinID)
        intensity = intensityList[basinIDindex]
        elevation = elevationList[basinIDindex]
        
        tempDf[k, "Block"] <- getBlock(polygonFile)
        tempDf[k, "Column"] <- getColumn(polygonFile)
        tempDf[k, "Row"] <- getRow(polygonFile)
        tempDf[k, "Subtile"] <- getSubtile(polygonFile)
        tempDf[k, "Basin"] <- polygonVect[k]$BasinID
        tempDf[k, "SourceImage"] <- listOfImageFiles[i]
        tempDf[k, "CropImage"] <- pngFilename
        tempDf[k, "Intensity"] <- intensity
        tempDf[k, "Elevation"] <- elevation
        # tempDf[k, "NAIPYear"] <- NA
      }
      
      mortalityDf = rbind(mortalityDf, tempDf)
    }
  }
}

# remove rows that are all NA (these were skipped because of invalid Extent)
mortalityDf = mortalityDf[rowSums(is.na(mortalityDf)) != ncol(mortalityDf), ] 

# shuffle rows
mortalityDf = mortalityDf[sample(1:nrow(mortalityDf), nrow(mortalityDf)), ]

# output the CSV file
write.table(mortalityDf, paste0(outputFolder, "mortality.csv"), row.names=FALSE, sep=",")
print(paste("done.:", Sys.time()))









