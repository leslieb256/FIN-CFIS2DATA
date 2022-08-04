# to RUN: runApp("c:/RDevelopment")

# NOTES:
# Some options on UI removed as Shiny Version on the servers I am using is pretty old

require("shiny")

ui <- fluidPage(
  theme = "default.css",
  tags$title("CFIS to Data Convertor"),
  tags$h1("CFIS to Data Convertor - WARNING TEST"),
  fluidRow(
    column(12,
           tags$p("Created to convert the information contained in a CFIS non-zero schedule file in to a table of data that is useable in excel."),
           tags$p("Takes as input one or more CFIS All non-zero schedule files in xlsx format with one column of $ data. Optionally can also attach the details from a mapping table."),
           tags$p("The spreadsheet with the mapping table must have one column called \"CFISKey\" with the following format: ss.ss.ss.llll : schedule id.line id : e.g.: 0.1.5.299 is schedule 0.1.5 line 299"),
           tags$p("If you get \"Error:'by' must specify a uniquely valid column\" it means your mapping table either does not have a column called \"CFISKey\" or has more than one")
    )
  ),
  fluidRow(
    column(4,
           tags$h2("Select CFIS \"All Non-Zero Schedule file(s)\" to process"),
           tags$p("WARNING: Must be saved as .xlsx files. .xls will not load"),
           fileInput('inputFiles',
                     'Select CFIS All Non-Zero Schedule Report(s) to process',
                     multiple = TRUE,
                     accept=c('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','.xlsx')
           ),
           tags$hr(),
           tags$h2("Optional: Add Mapping File"),
           fileInput('mappingFile',
                     'Select a file containing a mapping table',
                     multiple = FALSE,
                     accept=c('application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','.xls','.xlsx')
           ),
           textInput("mappingWorksheetName", "Name of worksheet with mapping table", value="oCFISMappingTable")

    ),
    column(4,
           tags$h2("Modify the output table:"),
           tags$h3("Rounding of $"),
           radioButtons( "rounding","Rounding Options", c("$" = "dollars","$000" = "thousands"), selected = "thousands"),
           tags$hr(),
           tags$h3("Include/exclude data"),
           checkboxInput("appropData","Appropriation Data", TRUE),
           checkboxInput("finData","Financial Data", FALSE),
           tags$hr(),
           tags$h3("Review lines with missing data"),
           checkboxInput("errorData","Show only lines with \"NA\" values", FALSE),
           tags$hr(),
           tags$h3("Apply a mapping table"),           
           checkboxInput("useMapping","Add mapping table columns to data", TRUE)
           
    ),
    column(4,
           tags$h2("Download output"),
           downloadButton("downloadButtonCsv", "Download .csv")
           )
  ),

  fluidRow(
    column(12,
           tags$h2("Processed CFIS report data"),
           tableOutput('contents')
    )
  )
  
)
