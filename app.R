library(shiny)
library(readxl)
library(writexl)
library(DT)

# Función para calcular el dígito verificador
calcular_digito_verificador <- function(run) {
  digitos <- rev(as.integer(strsplit(as.character(run), "")[[1]]))
  pesos <- rep(2:7, length.out = length(digitos))
  suma <- sum(digitos * pesos)
  dv <- 11 - (suma %% 11)
  dv <- ifelse(dv == 11, 0, ifelse(dv == 10, "K", dv))
  return(dv)
}

# Interfaz de Usuario (UI)
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-color: #f4f5f7;
        font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
        color: #333;
      }
      .shiny-input-container {
        margin-bottom: 15px;
      }
      .well {
        background-color: #fff;
        border-radius: 8px;
        box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.1);
        border: none;
      }
      #calculate {
        background-color: #6a4c93;
        color: white;
        border-color: #6a4c93;
        border-radius: 5px;
        padding: 8px 16px;
        margin-bottom: 10px;
        margin-right: 5px;
      }
      #calculate:hover {
        background-color: #5a3e7d;
        border-color: #5a3e7d;
      }
      #download {
        background-color: #009688;
        color: white;
        border-color: #00796b;
        border-radius: 5px;
        padding: 8px 16px;
        margin-bottom: 10px;
      }
      #download:hover {
        background-color: #00796b;
        border-color: #005f56;
      }
      .title-panel {
        text-align: left;
        color: #6a4c93;
        margin-bottom: 20px;
        font-size: 24px;
        font-weight: bold;
      }
      .instructions {
        margin-bottom: 20px;
        font-size: 14px;
        color: #555;
      }
      .button-group {
        display: flex;
        gap: 10px;
      }
      .warning {
        margin-top: 20px;
        font-size: 12px;
        color: #d9534f; /* Color rojo para advertencias */
        text-align: left;
      }
    "))
  ),

  titlePanel(
    div(class = "title-panel", "Cálculo de Dígito Verificador de RUN")
  ),

  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Subir archivo Excel", accept = ".xlsx"),
      textInput("run_column", "Nombre de la columna de RUN", value = "RUN"),
      helpText("Asegúrese de que el nombre de la columna de RUN coincida exactamente con el nombre en el archivo Excel, incluyendo mayúsculas y minúsculas."),

      # Instrucciones adicionales
      div(class = "instructions",
          strong("Instrucciones:"),
          p("1. Suba su archivo Excel que contiene la columna de RUN."),
          p("2. Especifique el nombre de la columna de RUN."),
          p("3. Haga clic en 'Calcular DV' para agregar el dígito verificador."),
          p("4. Finalmente, haga clic en 'Descargar archivo' para obtener el archivo actualizado."),
          p("5. El archivo tendrá la columna 'DV_CALC' en donde se registrará en DV calculado.")
      ),

      div(
        class = "button-group",
        actionButton("calculate", "Calcular DV"),
        downloadButton("download", "Descargar archivo")
      ),
      class = "well"
    ),

    mainPanel(
      DTOutput("table"),
      textOutput("data_message"),
      class = "well"
    )
  ),
)

# Lógica del Servidor (Server)
server <- function(input, output, session) {
  data <- reactiveVal(NULL)

  observeEvent(input$file, {
    req(input$file)
    df <- read_excel(input$file$datapath)
    data(df)
    showNotification(
      paste("Columnas disponibles en el archivo: ", paste(colnames(df), collapse = ", ")),
      type = "message"
    )
  })

  observeEvent(input$calculate, {
    req(data())
    df <- data()
    run_column <- input$run_column

    if (!(run_column %in% colnames(df))) {
      showNotification(
        paste("La columna '", run_column, "' no existe en el archivo. Verifique el nombre y si tiene mayúsculas o minúsculas.", sep = ""),
        type = "error"
      )
    } else {
      # Eliminar columna 'dv_calc' si ya existe
      df$dv_calc <- NULL

      # Calcular dv y agregarlo al data frame
      df$dv_calc <- sapply(df[[run_column]], calcular_digito_verificador)

      # Actualizar el objeto reactivo con los datos modificados
      data(df)
      showNotification("Cálculo de DV completado.", type = "message")
    }
  })

  output$table <- renderDT({
    req(data())
    datatable(data(), options = list(pageLength = 10, autoWidth = TRUE))
  })

  output$data_message <- renderText({
    "Nota: Los datos subidos no se guardan en ningún lugar. Se utilizan solo para el cálculo del dígito verificador."
  })

  output$download <- downloadHandler(
    filename = function() {
      paste("datos_con_dv_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(data())
      write_xlsx(data(), file)
    }
  )
}

# Ejecutar la aplicación Shiny
shinyApp(ui = ui, server = server)
