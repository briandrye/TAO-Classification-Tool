#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(terra)
library(stringr)


shinyServer(function(input, output) {
  
    rv <- reactiveValues(
      currentCroppedImageIndex = 0,
      csvDf = data.frame()
    )

    observeEvent(input$loadCsv, {
      rv$csvDf <- read.csv(paste0(input$outputFolder, "mortality.csv"), header=TRUE, sep=",")
      # adjust index to the first row that doesn't have MortalityStatus set
      naIndexes = which(is.na(rv$csvDf["MortalityStatus"]))
      if(length(naIndexes) > 0)
      {
        rv$currentCroppedImageIndex = naIndexes[1]
      }
      else
      {
        rv$currentCroppedImageIndex = 1
      }
    })

    observeEvent(input$firstImage, {
      rv$currentCroppedImageIndex <- 1
    })
    observeEvent(input$previousImage, {
      if(rv$currentCroppedImageIndex > 1)
      {
        rv$currentCroppedImageIndex <- rv$currentCroppedImageIndex - 1
      }
    })
    observeEvent(input$nextImage, {
      if(rv$currentCroppedImageIndex < nrow(rv$csvDf))
      {
        rv$currentCroppedImageIndex <- rv$currentCroppedImageIndex + 1
      }
    })
    observeEvent(input$lastImage, {
      rv$currentCroppedImageIndex <- nrow(rv$csvDf)
    })
    observeEvent(input$saveMortality, {
      if(nrow(rv$csvDf) > 0)
      {
        rv$csvDf[rv$currentCroppedImageIndex, "MortalityStatus"] = input$mortalityStatus
        rv$csvDf[rv$currentCroppedImageIndex, "Nadir"] = input$nadir
        rv$csvDf[rv$currentCroppedImageIndex, "Error"] = input$error
        write.table(rv$csvDf, paste0(input$outputFolder, "mortality.csv"), row.names=FALSE, sep=",")
        if(rv$currentCroppedImageIndex < nrow(rv$csvDf))
        {
          rv$currentCroppedImageIndex <- rv$currentCroppedImageIndex + 1
        }
        else
        {
          print("no more polygons to classify")
          rv$currentCroppedImageIndex <- nrow(rv$csvDf)
        }
      }
      else
      {
        print("Error: mortality.csv not loaded. Click 'Load mortality.csv' button. ")
      }
    })

  
    output$showCroppedImage <- renderImage({
      if(rv$currentCroppedImageIndex > 0)
      {
        cropImage = rv$csvDf[rv$currentCroppedImageIndex, "CropImage"]
        imageFile = paste0(input$outputFolder, cropImage)
        list(src = imageFile, width=400, height=400)
      }
      else
      {
        list(src = '')
      }
    }, deleteFile = FALSE)
    
    output$csvPath <- renderText({
      tempPath = paste0(input$outputFolder, "mortality.csv")
      if(file.exists(tempPath))
      {
        "mortality.csv found"
      }
      else
      {
        "mortality.csv not found"
      }
    })
    output$croppedImageIndex <- renderText({
      paste(rv$currentCroppedImageIndex, "/", nrow(rv$csvDf), 
            " : ", toString(rv$csvDf[rv$currentCroppedImageIndex, "MortalityStatus"]),
            " : ", toString(rv$csvDf[rv$currentCroppedImageIndex, "Nadir"]),
            " : ", toString(rv$csvDf[rv$currentCroppedImageIndex, "Error"])
      )
    })
    
    output$croppedImagePath <- renderText({
      paste0("Image: ",input$outputFolder, rv$csvDf[rv$currentCroppedImageIndex, "CropImage"])
    })
    

})
