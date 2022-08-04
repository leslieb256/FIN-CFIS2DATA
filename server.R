require("shiny")
# require("openxlsx")

# load the functions to process the CFIS data

# FOUND THE ISSUES:
# https://stackoverflow.com/questions/30624201/read-excel-in-a-shiny-app


source(".Rprofile")
source("CFIS2Data.R")


shinyServer(function(input, output) {

   # rawCFISData <- com.araitanga.c2d.core.TEMPLATEDataFrame[FALSE,]  
   rawCFISData <- reactive({

      data = com.araitanga.c2d.core.TEMPLATEDataFrame[FALSE,]
      
      inFiles <- input$inputFiles      
          
      if(is.null(inFiles)) {
        return(NULL)
      }
      
      # Process files
      else {
        withProgress(message = "Reading workbooks", value = 0, {
          # count the number of files uploaded
          numFiles = nrow(inFiles)
          
          for (file in 1:numFiles) {
            incProgress(1/numFiles, detail = paste("Processing workbook ", input$inputFiles[[file,"name"]]))
            # print(input$inputFiles[[file, "datapath"]])
             # read_excel(input$inputFiles[[file, "datapath"]], sheet="catsM")
             # com.araitanga.c2d.core.processXLWorkbook(input$inputFiles[[file, "datapath"]])
            
            # tempHolding = read_excel(input$inputFiles[[file, "datapath"]],sheet="catsM")
            tempHolding <- com.araitanga.c2d.core.processXLWorkbook_progressBar(input$inputFiles[[file, "datapath"]])
            data = rbind(data,tempHolding)
          }
        })
      }
      
      rawCFISData <- data
    
  })
    
  mappingTable <- reactive({
      inFileMap <- input$mappingFile      
      
      if(is.null(inFileMap)) {
         #print("No mapping table to process")
         return(NULL)
      }
      return((data <- read.xlsx(inFileMap$datapath, sheet=input$mappingWorksheetName)))
   })
  
  # puts the data in to a reactive component that can be accessed by other components.
  resultTable <- reactive ({
     
     resultOutput <- NULL
     CFISMapping <- mappingTable()
     
     if (!is.null(rawCFISData())){
 
        scheduleData <- rawCFISData()

        # APPLY MODIFIERS
        # Remove unwanted data
        if(!input$appropData) {
           scheduleData <- scheduleData[!grepl('^0',scheduleData$c2dCFISKey),]
           
        }
        if(!input$finData) {
           scheduleData <- scheduleData[!grepl('^1',scheduleData$c2dCFISKey),]
        }
        
        if(!is.null(CFISMapping) && input$useMapping){
           scheduleData <- merge(x = scheduleData, y = CFISMapping, by.x="c2dCFISKey", by.y="CFISKey", all.x=TRUE)
        }
        
        if(input$errorData){
           #print("clearing NAs")
           #print(complete.cases(scheduleData))
           scheduleData <- scheduleData[!complete.cases(scheduleData),]
        }
        
        if(input$rounding == "dollars"){
           # data comes out of CIFS as $000, this lets you change it to a raw $ value
           scheduleData$c2dCFISLineAmt <- as.integer(scheduleData$c2dCFISLineAmt) * 1000
        }
        
        resultOutput <- scheduleData
        
     }
     
     return(resultOutput)
     
  })
  
  # feeds the resultsTable to the table creation code
  output$contents <- renderTable(resultTable(), digits = 0, striped = TRUE)
  
  
  output$downloadButtonCsv <- downloadHandler(
     filename = function(){"CFIS2DataOutput.csv"}, 
     content = function(fname){
        write.csv(resultTable(), fname, row.names = FALSE)
     }
  )
  
  output$testText <- renderText({paste( unlist ("2. moose") , collapse = " ")})
  
})