#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
#library('sf')
library('terra')
library('stringr')



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



shinyServer(function(input, output) {
  
    rv <- reactiveValues(
      currentCroppedImageIndex = 1,
      csvDf = data.frame()
      )

    observeEvent(input$loadCsv, {
      rv$csvDf <- read.csv(paste0(input$outputFolder, "mortality.csv"), header=TRUE, sep=",")
      rv$currentCroppedImageIndex = 1
    })

    observeEvent(input$firstImage, {
      rv$currentCroppedImageIndex <- 1
    })
    observeEvent(input$previousImage, {
      rv$currentCroppedImageIndex <- rv$currentCroppedImageIndex - 1
    })
    observeEvent(input$nextImage, {
      rv$currentCroppedImageIndex <- rv$currentCroppedImageIndex + 1
    })
    observeEvent(input$lastImage, {
      rv$currentCroppedImageIndex <- nrow(rv$csvDf)
    })
    observeEvent(input$liveButton, {
      rv$csvDf[rv$currentCroppedImageIndex, "IsLive"] = "1"
      write.table(rv$csvDf, paste0(croppedImagesOutputFolder, "mortality.csv"), row.names=FALSE, sep=",")
      rv$currentCroppedImageIndex <- rv$currentCroppedImageIndex + 1
    })
    observeEvent(input$deadButton, {
      rv$csvDf[rv$currentCroppedImageIndex, "IsLive"] = "0"
      write.table(rv$csvDf, paste0(croppedImagesOutputFolder, "mortality.csv"), row.names=FALSE, sep=",")
      rv$currentCroppedImageIndex <- rv$currentCroppedImageIndex + 1
    })
    
    observeEvent(input$createImages, {
      if(input$createImages > 0)
      {
        startTime = Sys.time()
        req(input$outputFolder, input$shapeFiles, input$imageFiles, input$margin)
        croppedImagesOutputFolder = input$outputFolder
        withProgress(message = 'Processing...', value = 0, {
          # load *_Polygon.shp files
          # \\172.25.182.82\pfc-frl\01_LiDAR_data\Processed_FUSION\California\SSARR_2020_rerun\Segments_0p75METERS
          # copied some folders from network to local computer for testing
          listOfPolygonFiles <-
            list.files(
              path = input$shapeFiles,
              pattern = "\\Polygons.shp$",
              full.names = TRUE,
              ignore.case = TRUE
            )
          
          listOfHighPointFiles <-
            list.files(
              path = input$shapeFiles,
              pattern = "\\HighPoints.shp$",
              full.names = TRUE,
              ignore.case = TRUE
            )
          
          # check to see if both lists are same length
          if (length(listOfPolygonFiles) != length(listOfHighPointFiles))
          {
            print("length of Polygon file list doesn't match length of High Point files")
            return(NULL)
          }
          
          # array to hold number of polygons in each shp file
          polygonCounts <-array(dim = length(listOfPolygonFiles))
          
          # save counts
          for (i in 1:length(listOfPolygonFiles))
          {
            tempSpatVector <- vect(listOfPolygonFiles[i])
            polygonCounts[i] <- nrow(tempSpatVector)
          }
          
          totalNumberOfPolygons <- sum(polygonCounts)
          
          desiredSampleCount = as.numeric(input$sampleSize)
          
          # do a sample on each .shp file according to its percentage of total number
          set.seed(0)
          
          #create a spatVector of all the sampled polygons
          sampledPolygonSpatVector <- vect()
          sampledHighPointSpatVector <- vect()
          
          for (i in 1:length(listOfPolygonFiles))
          {
            tempPolygonSpatVector <- vect(listOfPolygonFiles[i])
            amountToSample <- round(desiredSampleCount * (polygonCounts[i] / totalNumberOfPolygons))
            tempSampleRows = sample(nrow(tempPolygonSpatVector), size = amountToSample)
            tempSampledPolySpatVector <- tempPolygonSpatVector[tempSampleRows, ]
            # store the Block, Column, Row, Subtile for this polygon
            tempSampledPolySpatVector$Block <- getBlock(listOfPolygonFiles[i])
            tempSampledPolySpatVector$Column <- getColumn(listOfPolygonFiles[i])
            tempSampledPolySpatVector$Row <- getRow(listOfPolygonFiles[i])
            tempSampledPolySpatVector$Subtile <- getSubtile(listOfPolygonFiles[i])
            
            sampledPolygonSpatVector <- rbind(sampledPolygonSpatVector, tempSampledPolySpatVector)
            # sample same rows from listOfHighPointsFiles[i]
            tempHighPointSpatVector <- vect(listOfHighPointFiles[i])
            tempSampledHighPointSpatVector <- tempHighPointSpatVector[tempSampleRows, ]
            sampledHighPointSpatVector <- rbind(sampledHighPointSpatVector, tempSampledHighPointSpatVector)
            setProgress((1/10)*(i/length(listOfPolygonFiles)), detail = paste0("sampling ", i, "/", length(listOfPolygonFiles)))
          }
          
          # confirm that we have same number of geometries... sampling is done
          if (nrow(sampledPolygonSpatVector) != nrow(sampledHighPointSpatVector))
          {
            print("Error: Polygon and HighPoint row mismatch.")
          }
          
          listOfImageFiles <-
            list.files(
              path = input$imageFiles,
              pattern = "\\.tif$",
              full.names = TRUE,
              ignore.case = TRUE,
              recursive = TRUE
            )
          
          # use CRS (from first raster) to update CRS of Polygons and HighPoints
          crsSpatRaster <- rast(listOfImageFiles[1])
          sampledPolygonSpatVector <- project(sampledPolygonSpatVector, crsSpatRaster)
          sampledHighPointSpatVector <- project(sampledHighPointSpatVector, crsSpatRaster)
          
          # find polygons in image files... want to store:
          # i - this is the index into listOfImageFiles (so we can get file name)
          # j - this will be a list of indexes into sampledPolygonsSpatVector
          
          arrayOfImagesThatContainPolygons <- array()
          listOfPolygonsInImage <- list()
          arrayIndex = 1
          
          highPoints <- geom(sampledHighPointSpatVector, df=TRUE)
          highPoints[ , 'found'] <- 0 
          for (i in 1:length(listOfImageFiles))
          {
            tempSpatRaster <- rast(listOfImageFiles[i])
            # look for sampled high points inside the image extent
            # note: simple search... just loop through each high point. 
            # if we find all points, quit searching
            # highpoint (polygon) might be in more than one image
            # once found, mark the high point as found
            tempExtent <- ext(tempSpatRaster)
            polygons <- vector()
            
            for (j in 1:nrow(highPoints))
            {
              if(highPoints[j, "found"] == 1)
              {
                next
              }
              if (tempExtent$xmin < highPoints[j, 'x'] &&
                  tempExtent$xmax > highPoints[j, 'x'] &&
                  tempExtent$ymin < highPoints[j, 'y'] &&
                  tempExtent$ymax > highPoints[j, 'y'])
              {
                highPoints[j, "found"] <- 1
                polygons <- append(polygons, j)
              }
            }

            if (length(polygons) > 0)
            {
              arrayOfImagesThatContainPolygons[arrayIndex] <- i
              listOfPolygonsInImage[[arrayIndex]] <- polygons
              arrayIndex <- arrayIndex + 1
              if(all(highPoints[, "found"] == 1))
              {
                break
              }
            }
            setProgress(1/10 + (1/10)* (i/length(listOfImageFiles)), 
                        detail = "locating polygons in images")
          }
          
          # save cropped images (raster plus polygon) as .png
          # also create a csv file 
          csvDataframe = data.frame(matrix(nrow=0, ncol=8))
          names(csvDataframe) <- c("Block","Column","Row","Subtile","Basin","IsLive","FilePath","NAIPYear")
          
          for (i in 1:length(arrayOfImagesThatContainPolygons))
          {
            imageFileIndex = arrayOfImagesThatContainPolygons[i]
            print(imageFileIndex)
            print(listOfImageFiles[imageFileIndex])
            
            tempSpatRaster <-
              rast(listOfImageFiles[imageFileIndex])
            tempPolygonsIndexes <- listOfPolygonsInImage[[i]]
            
            # make a dataframe to save as a csv
            # Block, Column, Row, Subtile, Basin, IsLive, FilePath, NAIPYear
            tempCsvDataframe = data.frame(matrix(nrow=length(tempPolygonsIndexes), ncol=8))
            names(tempCsvDataframe) <- c("Block","Column","Row","Subtile","Basin","IsLive","FilePath","NAIPYear")
            
            for (j in 1:length(tempPolygonsIndexes))
            {
              polygonIndex <- tempPolygonsIndexes[j]
              tempExtent <-
                ext(sampledPolygonSpatVector[polygonIndex])
              tempExtent$xmin <- tempExtent$xmin - input$margin
              tempExtent$xmax <- tempExtent$xmax + input$margin
              tempExtent$ymin <- tempExtent$ymin - input$margin
              tempExtent$ymax <- tempExtent$ymax + input$margin
              croppedImage <- crop(tempSpatRaster, tempExtent)
              
              png(paste0(croppedImagesOutputFolder, polygonIndex, ".png"))
              tempPlot <- plotRGB(croppedImage)
              lines(geom(sampledPolygonSpatVector[polygonIndex])[, 'x'],
                    geom(sampledPolygonSpatVector[polygonIndex])[, 'y'],
                    col = "red")
              dev.off()
              
              # fill in dataframe
              tempCsvDataframe[j, "Block"] <- sampledPolygonSpatVector[polygonIndex]$Block
              tempCsvDataframe[j, "Column"] <- sampledPolygonSpatVector[polygonIndex]$Column
              tempCsvDataframe[j, "Row"] <- sampledPolygonSpatVector[polygonIndex]$Row
              tempCsvDataframe[j, "Subtile"] <- sampledPolygonSpatVector[polygonIndex]$Subtile
              tempCsvDataframe[j, "Basin"] <- sampledPolygonSpatVector[polygonIndex]$BasinID
#              tempCsvDataframe[j, "FilePath"] <- listOfImageFiles[imageFileIndex]
#              tempCsvDataframe[j, "NAIPYear"] <- NA
              
            }
            
            csvDataframe <- rbind(csvDataframe, tempCsvDataframe)
            setProgress((2/10) + (i/length(arrayOfImagesThatContainPolygons) *
                                                (8 / 10)),
                        detail = paste("cropping images...", i)
            )
          }
        })
        # output the CSV file
        write.table(csvDataframe, paste0(croppedImagesOutputFolder, "mortality.csv"), row.names=FALSE, sep=",")
        rv$currentCroppedImageIndex = 0
        csvDf = data.frame()
        endTime = Sys.time()
        totalTime = endTime - startTime
        print(paste("done preprocessing:", totalTime))
      }
      else
      {
        print("initial state")
      }
    })
  
    output$showCroppedImage <- renderImage({
      imageFile = paste0(input$outputFolder, rv$currentCroppedImageIndex, ".png")
      list(src = imageFile, width=400, height=400)
    }, deleteFile = FALSE)
    
    output$csvPath <- renderText({
      paste0(input$outputFolder, "mortality.csv")
    })
    output$croppedImageIndex <- renderText({
      paste("Index: ", rv$currentCroppedImageIndex, "Live: ", toString(rv$csvDf[rv$currentCroppedImageIndex, "IsLive"]))
    })
    
    output$croppedImagePath <- renderText({
      paste0("Image: ",input$outputFolder, rv$currentCroppedImageIndex, ".png")
    })
    
    output$csvTable <- renderDataTable({
      if(nrow(rv$csvDf))
      {
        tempdf <- cbind(rownames(rv$csvDf), rv$csvDf[, 1:6])
        colnames(tempdf)[1] <- "index"
        tempdf
      }
      else
      {
        rv$csvDf
      }
    }, options=list(pageLength=5, lengthMenu=c(5, 100))
    )

#    output$polygonInfo <- renderTable({
#      if(nrow(rv$csvDf))
#      {
#        rv$csvDf[rv$currentCroppedImageIndex, ]
#        rv$csvDf
#      }
#    })

})