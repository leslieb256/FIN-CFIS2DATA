# Used to reformat the All Non-Zero Schedules from CFIS report in to a data format

# source("P:/r/common.Rprofile")
# https://google.github.io/styleguide/Rguide.html


require(openxlsx)

# TODO
# write a thing to find all the amount columns - basically walk the sheet until it finds the first one
# see the cleanRAW schedule - it needs to collate all the iteration of the for amount column and combine as "wroking sheet"
# for the final return.
# I think this needs to be a copy of the TEMPLATE data frame that gets added to called maybe "cleanToReturn" since
# working sheet has renamed columns we want to keep, actually, the best idea might be to repreocess the entire sheet
# for each amount column might be easier.
# It is should be smart enough to not need to worry about teh odd formatting on the last worksheet
# that has been taken care of in the working out of the amot column.

# create function to trim whitespace
com.araitanga.c2d.core.trim <- function (x) gsub("^\\s+|\\s+$", "", x)

# Create dataframe TEMPLATE for output format
# do not put values in this frame!
com.araitanga.c2d.core.TEMPLATEDataFrame <- data.frame(
   c2dExerciseID=character(),
   c2dCFISExerciseShtDesc=character(),
   c2dCFISPeriodEnd=character(),
   c2dCFISKey=character(),
   c2dCFISLineShtDesc=character(),
   c2dCFISLineAmt=integer(),
   c2dProcessDate=character()
)



# function to read a dataframe, determine if it is a 'valid' schedule
# returns dataframe of clean worksheet data
com.araitanga.c2d.core.cleanRawSchedule <- function(originalSheet) {
   # The title can be in any column in the first row of the worksheet so convert the first row to a string
   scheduleID <- gsub(":",".",regmatches(toString(originalSheet[1,]), regexpr("\\d+:\\d+:\\d+",toString(originalSheet[1,]))))
   # regmatches(toString(workingSheet[1,]), regexpr("\\d+:\\d+:\\d+",toString(workingSheet[1,])))
   
   # the column containing the schedule data we are interested in can change between schedules
   # if the dataRow changes it could also be set here
   dataColumnAmount <- -1
   dataRowExercise <- -1
   dataRowExerciseShortDescription <- -1
   dataRowPeriodEnd <- -1
   dataColumnAppropShortDescription <- -1
   
   # prepare empty dataframe if this is a schedule 
   unpivotedScheduleData <- com.araitanga.c2d.core.TEMPLATEDataFrame[FALSE,]
   

   # assumes the exercise ID above the amount column is on the same row as the LineID
   # what this will do is run over the worksheet once for each exercise in the worksheet
   # each time it runs over the worksheet it looks at a different amount column
   # then it combines it all up in the main dataframe.
   
   lineIDColumn <- com.araitanga.c2d.core.getLineIDLocation(originalSheet)$col
   lineIDRow <- com.araitanga.c2d.core.getLineIDLocation(originalSheet)$row
   AmtColumns <- com.araitanga.c2d.core.getAmountColumns(originalSheet, lineIDRow )

   for (AmtColumn in AmtColumns){
      # initalise workingSheet as a copy of Original Sheet since it will be destructivly manipulated.
      workingSheet <- originalSheet
      
      # the format for the column names on import is "X" + Column number
      ShtDescColumn <- lineIDColumn + 2
      colnames(workingSheet)[colnames(workingSheet)==paste0("X",lineIDColumn)] <- "c2dCFISLineNo"
      colnames(workingSheet)[colnames(workingSheet)==paste0("X",ShtDescColumn)] <- "c2dCFISLineShtDesc"
      colnames(workingSheet)[colnames(workingSheet)==paste0("X",AmtColumn)] <- "c2dCFISLineAmt"

      dataColumnAmount <- AmtColumn

      dataColumnAppropShortDescription <- ShtDescColumn
      
      # rows assumed to be constant
      dataRowExercise <- lineIDRow
      dataRowExerciseShortDescription <- lineIDRow + 1
      dataRowPeriodEnd <- lineIDRow + 2
   

      #print(paste0("scheduleID: ",scheduleID))
      #print(paste0("    exercise: ",workingSheet[dataRowExercise,dataColumnAmount]))
      #print(paste0("    excerciseShortDescription: ",workingSheet[dataRowExerciseShortDescription,dataColumnAmount]))
      #print(paste0("    periodEnd: ",workingSheet[dataRowPeriodEnd,dataColumnAmount]))
      
      # Add columns with schedule information to dataframe
      workingSheet$c2dCFISscheduleID<-scheduleID
      workingSheet$c2dCFISExerciseID<-as.character(workingSheet[dataRowExercise,dataColumnAmount])
      workingSheet$c2dCFISExerciseShtDesc<-as.character(workingSheet[dataRowExerciseShortDescription,dataColumnAmount])
      workingSheet$c2dCFISPeriodEnd<-as.character(workingSheet[dataRowPeriodEnd,dataColumnAmount])
      # Create a full CFISKey
      workingSheet$c2dCFISKey <- paste(workingSheet$c2dCFISscheduleID,".",workingSheet$c2dCFISLineNo,sep="")
      
      # add todays date as the processed date
      workingSheet$c2dProcessDate<-format(Sys.Date(), format="%Y-%m-%d")
      
      # Remove rows which are non-appropriation (empty or header)
      # the next line to remove zero values apparently does not work with NA values
      
      # remove leading and trailing whitespace from CFISLineShtDesc
      # workingSheet$CFISLineShtDesc <- com.araitanga.c2d.core.trim(workingSheet$CFISLineShtDesc)
      # remove rows where there is no appropriation short description ie: it is NA
      workingSheet <- workingSheet[complete.cases(workingSheet[,dataColumnAppropShortDescription]),]
      # remove rows where there is no amount, no even zero ie: it is NA
      workingSheet <- workingSheet[complete.cases(workingSheet[,dataColumnAmount]),]
      # convert the CFISLineAmts to numbers (ensures these are numeric for next test) NOT REQUIRED
      # as.numeric(as.character(workingSheet$CFISLineAmt))
      # Remove rows which have a value of zero
      workingSheet <- workingSheet[!((workingSheet$"c2dCFISLineAmt")==0),]
      # filter unwanted columns before merge
      workingSheet<-workingSheet[c("c2dCFISLineAmt","c2dCFISKey","c2dCFISExerciseID","c2dCFISExerciseShtDesc","c2dCFISLineShtDesc","c2dCFISPeriodEnd","c2dProcessDate")]
      
      unpivotedScheduleData <- rbind(unpivotedScheduleData, workingSheet)
   }

   return(unpivotedScheduleData)

}

com.araitanga.c2d.core.processXLWorkbook <- function(workbook) {
   # If you make changes in here also make them to "com.araitanga.c2d.core.processXLWorkbook_progressBar"
   # create an empty copy of the output data frame template
   outputDataframe = com.araitanga.c2d.core.TEMPLATEDataFrame[FALSE,]
   
   for (worksheet in getSheetNames(workbook)){
         # print(paste0("sheet START:", worksheet))
         workingSheet <- read.xlsx(workbook, sheet = worksheet, colNames=FALSE)

         # if worksheet is a schedule then get the data from it.
         scheduleID <- gsub(":",".",regmatches(toString(workingSheet[1,]), regexpr("\\d+:\\d+:\\d+",toString(workingSheet[1,]))))
         # print(paste0("SchedID process: ",scheduleID," Length: ",length(scheduleID)))
         if (length(scheduleID) > 0 ) {
            # print("In the process lop heading to clean")
            tempHolding <- com.araitanga.c2d.core.cleanRawSchedule(workingSheet)
            outputDataframe <- rbind(outputDataframe, tempHolding)
         }
   }
   return(outputDataframe)
}

com.araitanga.c2d.core.processXLWorkbook_progressBar <- function(workbook) {
   # This should be the same as the function "com.araitanga.c2d.core.processXLWorkbook"
   outputDataframe = com.araitanga.c2d.core.TEMPLATEDataFrame[FALSE,]

   worksheetsToProcess <- (length((getSheetNames(workbook))))

   withProgress(message = "Reading worksheets", value = 0, {

      for (worksheet in getSheetNames(workbook)){
         incProgress(1/worksheetsToProcess, detail = paste("Processing worksheet: ", worksheet))
         
         workingSheet <- read.xlsx(workbook, sheet = worksheet, colNames=FALSE)
         # if worksheet is a schedule then get the data from it.
         scheduleID <- gsub(":",".",regmatches(toString(workingSheet[1,]), regexpr("\\d+:\\d+:\\d+",toString(workingSheet[1,]))))
         # print(paste0("from process loop: ",scheduleID))
         if (length(scheduleID) > 0 ) {
            tempHolding <- com.araitanga.c2d.core.cleanRawSchedule(workingSheet)
            outputDataframe <- rbind(outputDataframe, tempHolding)
         }
      }
   
   })

   return(outputDataframe)
}

com.araitanga.c2d.core.getLineIDLocation <- function(worksheetData) {
   # searches first 8 rows and 4 column of a datatable for the word "Line"
   # this implies which columns contain the data we are interested in.
   # for some reason the last worksheet seems to be formatted differently to the others
   # this seemed to be a more future proof way of dealing with odd formats than assuming the
   # last sheet was differnt.
   columnMax <- 4
   rowMax <- 8

   for (lineRow in (1:rowMax)){
      for (lineColumn in (1:columnMax)){
         if( !is.na(worksheetData[lineRow,lineColumn]) &&
             worksheetData[lineRow,lineColumn] == "Line"){
             # print(paste0("Row: ",lineRow, " | Column: ",lineColumn))
            line_location <- list("col" = lineColumn, "row" = lineRow)
            return (line_location)
            break
         }
      }
   }
   
}

com.araitanga.c2d.core.getAmountColumns <- function(worksheetData,exIDRow) {
   amtColumns <- c()
   for (column in (1:length(worksheetData[exIDRow,]))){
      if(length(grep("\\d+:\\d+:\\d+",worksheetData[exIDRow,column]))>0){
         # print(paste0("Row: ",exIDRow, " | Column: ",column," | "))
         amtColumns <- c(amtColumns,column)
      }
   }
   return(amtColumns)
}

# TESTING
# try sheets 25 and 44 in col1
# workbook <- "C:/RDevelopment/FIN-CFIS2DATA/Period Comparison Report - 604_2018_19OBU(HYEFU)-outyear0-2col.xlsx"
# TestSheetNEW <- read.xlsx(workbook, sheet = "Sheet44", colNames=FALSE)
# CleanSheet <- com.araitanga.c2d.core.cleanRawSchedule(TestSheetNEW)
# testOuptut <- com.araitanga.c2d.core.processXLWorkbook(workbook)

# com.araitanga.c2d.core.getLineIDColumn(TestSheet)

#TestfinalOutput <- com.araitanga.c2d.core.processXLWorkbook(workbook)
