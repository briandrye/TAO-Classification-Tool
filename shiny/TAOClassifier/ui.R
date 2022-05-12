#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("TAO Classifier"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
          textInput("sampleSize", "Sample size", "300"),
          textInput("shapeFiles", "Folder containing shape files (.shp)", "C:/Users/bdrye/Downloads/segmentsExample/Segments_0p75METERS/"),
          textInput("imageFiles", "Folder containing imagery files (.tif)", "C:/Users/bdrye/Downloads/NAIP_2020/NAIP_4Band_2020/imagery"),
          textInput("outputFolder", "Output folder (cropped images and csv)", "C:/Users/bdrye/Downloads/croppedImages/"),
          sliderInput("margin",
                        "Margin:",
                        min = 10,
                        max = 30,
                        value = 20),
            
            # output folder for cropped images (and csv file?)
          fluidRow(
            actionButton("createImages", "Preprocess Imagery"),
          ),
          fluidRow(
            #textOutput("csvPath"),
            actionButton("loadCsv", "Load CSV"),
            #textOutput("croppedImagePath")
          )
        ),

        # Show a plot of the generated distribution
        mainPanel(
          fluidPage(
            fluidRow(
              imageOutput("showCroppedImage")
            ),
            fluidRow(
              wellPanel(
                textOutput("croppedImageIndex"),
                actionButton("firstImage", "First"),
                actionButton("previousImage", "Prev"),
                actionButton("liveButton", "Live"),
                actionButton("deadButton", "Dead"),
                actionButton("nextImage", "Next"),
                actionButton("lastImage", "Last")
              )
            ),
            # fluidRow(
            #   wellPanel(
            #     radioButtons("cantTell", "Can't Tell Reason", c("Blurry", "No Tree Present", "Other"), selected=character(0)),
            #     actionButton("cantTell", "Can't Tell"),
            #     tableOutput("polygonInfo")
            #   )
            # ),
            fluidRow(
              wellPanel(
                dataTableOutput("csvTable"),
              )
            )
          )
        )
    )
))
