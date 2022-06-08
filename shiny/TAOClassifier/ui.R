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
          wellPanel(
            h4("Inputs"),
            # textInput("shapeFiles", "Folder containing shape files (.shp)", "D:/Segments_0p75METERS/"),
            textInput("shapeFiles", "Folder containing shape files (.shp)", "D:/notfound/"),
            textInput("imageFiles", "Folder containing imagery files (.tif)", "C:/Users/bdrye/Downloads/NAIP_2020/NAIP_4Band_2020/imagery"),
          ),
          wellPanel(
            h4("Configuration"),
            textInput("sampleSize", "Sample size", "30"),
            sliderInput("margin",
                        "Margin:",
                        min = 10,
                        max = 30,
                        value = 20),
          ),
          wellPanel(
            h4("Outputs"),
            textInput("outputFolder", "Output folder (cropped images and mortality.csv)", "C:/Users/bdrye/Downloads/croppedImages/"),
          ),
          
            
          fluidRow(
            "Step 1: ",
            actionButton("createImages", "Preprocess Imagery"),
          ),
          fluidRow(
            textOutput("csvPath"),
            "Step 2: ",
            actionButton("loadCsv", "Load mortality.csv"),
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
                actionButton("nextImage", "Next"),
                actionButton("lastImage", "Last")
              )
            ),
            fluidRow(
              wellPanel(
                selectInput("mortalityStatus", "Mortality Status:",
                            c("Broken top/Damaged crown, live" = "broken_top_damaged_crown_live",
                              "Browning top, live" = "browning_top_live",
                              "Coarse Woody Debris" = "coarse_woody_debris",
                              "Gray phase" = "gray_phase",
                              "Gray phase, multiple" = "gray_phase_multiple",
                              "Ground" = "ground",
                              "Live tree" = "live_tree",
                              "Live understory vegetation/small trees" = "live_understory_vegetation_small_trees",
                              "Live tree, multiple" = "live_tree_multiple",
                              "Mixed gray phase and live trees" = "mixed_gray_phase_and_live_trees",
                              "Mixed yellow/red phase and live trees" = "mixed_yellow_red_phase_and_live_trees",
                              "Other" = "other",
                              "Red phase" = "red_phase",
                              "Red phase, multiple" = "red_phase_multiple",
                              "Rock/Boulder" = "rock_boulder",
                              "Shadow" = "shadow",
                              "Snag, no branches, bare ground" = "snag_no_branches_bare ground",
                              "Snag, no branches, ground vegetation" = "snag_no_branches_ground_vegetation",
                              "Snags, ground vegetation" = "snags_ground_vegetation",
                              "Snags, no branches, bare ground" = "snags_no_branches_bare_ground",
                              "Unknown" = "Unknown",
                              "Yellowing tree, multiple" = "yellowing_tree_multiple",
                              "Yellowing tree, recent dead" = "yellowing_tree_recent_dead")),
                selectInput("nadir", "Nadir",
                            c("On" = "on", "Tilt" = "tilt", "Off" = "off")),
                selectInput("error", "Error",
                            c("Main, Oversegmentation" = "main_oversegmentation", "Associate, Oversegmentation" = "associate_oversegmentaion")),
                actionButton("saveMortality", "Update mortality.csv"),
              )
            ),
            # fluidRow(
            #   wellPanel(
            #     dataTableOutput("csvTable"),
            #   )
            # )
          )
        )
    )
))
