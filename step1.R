# library(raster)
library(terra)
library(stats)

# step 1
# create high point csv files that have two new columns: Intensity and Elevation
# Average Intensity is calculated by applying basinMap to intensityRast
# then we can "extract" the average intensity for each high point

# Elevation comes from topo_elevation_15M_30METERS.img
# copied from Z:\01_LiDAR_data\Processed_FUSION\California\SSARR_2020_rerun\TopoMetrics_30METERS
# resolution is 30m so skip averaging, just extract

#################
# user configured
#################

# source folder for Polygon .shp files 
shapeFolder = "D:/Segments_0p75METERS/"

# path to raster containing elevation info 
elevationFile = "D:/TopoMetrics_30METERS/topo_elevation_15M_30METERS.img"

# new csv files will be put here. This will be "inputFolder" in step2.R
outputFolder = "D:/step1/"

#####################
# end user configured
#####################



print(Sys.time())

listOfPolygonFiles = list.files(path = shapeFolder, pattern = "\\Polygons.shp$", full.names = TRUE, ignore.case = TRUE)
listOfHighPointFiles = list.files(path = shapeFolder, pattern = "\\HighPoints.shp$", full.names = TRUE, ignore.case = TRUE)
listOfBasinMapFiles = list.files(path = shapeFolder, pattern = "\\Basin_Map.img$", full.names = TRUE, ignore.case = TRUE)
listOfIntensityFiles = list.files(path = shapeFolder, pattern = "\\INT_GE_2m_0p75METERS.img$", full.names = TRUE, ignore.case = TRUE)


elevationRast = rast()

listOfPolygonFiles
listOfHighPointFiles
listOfBasinMapFiles
listOfIntensityFiles

for(i in 1:length(listOfHighPointFiles))
{
  basinMapRast = rast(listOfBasinMapFiles[i])
  intensityRast = rast(listOfIntensityFiles[i])
  # basinMapRast is bigger than intensityRast, crop basinMap to match intensity
  croppedBasinMapRast = crop(basinMapRast, intensityRast)
  # zonal can take a long time to finish... 
  # averageBasinIntensity = zonal(intensityRast, croppedBasinMapRast, "mean", as.raster=TRUE)
  # averageBasinIntensity = raster::zonal(intensityRast, croppedBasinMapRast, "mean", as.raster=TRUE)
  
  averageBasinIntensity = zonal(intensityRast, croppedBasinMapRast, \(i) mean(i, na.rm=T), as.raster=TRUE)
  
  # plot(croppedBasinMapRast)
  # plot(averageBasinIntensity)
  # plot(intensityRast)

  # sanity checks... basinMapRast is bigger than intensityRast
  # 
  # plot(elevationRast)
  # plot(ext(basinMapRast), add=TRUE)
  # plot(ext(intensityRast), add=TRUE)
  # plot(basinMapRast, add=TRUE)
  # plot(intensityRast, add=TRUE)

  highPointVector = vect(listOfHighPointFiles[i])

  # get average intensity for highPoints
  intensityForEachHighPoint = extract(averageBasinIntensity, highPointVector)
  # rename so cbind adds "Intensity" as column name
  Intensity = intensityForEachHighPoint$Layer_1
  # get approximate elevation for highPoints
  elevationForEachHighPoint = extract(elevationRast, highPointVector)
  Elevation = elevationForEachHighPoint$Layer_1
  
  highPointIntensityElevation = cbind(highPointVector, as.data.frame(Intensity), as.data.frame(Elevation))
  highPointIntensityElevation$PolygonFile = basename(listOfPolygonFiles[i])
  
  # view highpoints that have NA for Intensity... 
  # most are on the edge of the intensity raster
  # plot(intensityRast)
  # plot(highPointIntensityElevation[complete.cases(highPointIntensityElevation$Intensity),], col="black", add=TRUE)
  # plot(highPointIntensityElevation[is.na(highPointIntensityElevation$Intensity),], col="red", add=TRUE)

  # view highpoints that have NA for Elevation... 
  # all are on edge
  # plot(crop(elevationRast, croppedBasinMapRast))
  # plot(highPointIntensityElevation[complete.cases(highPointIntensityElevation$Elevation),], col="black", add=TRUE)
  # plot(highPointIntensityElevation[is.na(highPointIntensityElevation$Elevation),], col="red", add=TRUE)
  
  # get rid of rows that have NA for Intensity or Elevation???
  # assume so
  completeRows = complete.cases(as.data.frame(highPointIntensityElevation))
  completeDf = highPointIntensityElevation[completeRows, ]

  print(listOfHighPointFiles[i])
  print(paste("Discarded rows: ", sum(completeRows == FALSE), "/", length(highPointIntensityElevation)))

  # output a new high point CSV file that has intensity and elevation
  filename = basename(listOfHighPointFiles[i])
  csvFilename = sub("HighPoints.shp", "HighPoints_IntensityElevation.csv", filename)
  write.table(completeDf, paste0(outputFolder, csvFilename), row.names=FALSE, sep=",")
  print(Sys.time())
}

