library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(googlesheets4)
library(tibble)

# Charger les fonctions définies dans test.R
source('test.R')

# Charger les données Google Sheets
url <- "https://docs.google.com/spreadsheets/d/1T6GJz7YVZkFwlvuOO5oVjDM5M4gFqFQpTkZVHiF4zO0/edit?gid=1553056256"
data <- lire_toutes_les_feuilles3(url)

# 🎨 Interface
ui <- dashboardPage(
  dashboardHeader(title = "Suivi des Hospitalisations"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Tableau des patients", tabName = "table", icon = icon("table")),
      menuItem("Visualisation par service", tabName = "service", icon = icon("chart-bar"))
    )
  ),
  dashboardBody(
    tabItems(
      # 🧾 Onglet 1 : Table des patients
      tabItem(tabName = "table",
              fluidRow(
                box(title = "Liste des patients hospitalisés", width = 12, status = "primary", solidHeader = TRUE,
                    DTOutput("table_patients"))
              )
      ),
      # 📊 Onglet 2 : Par service
      tabItem(tabName = "service",
              fluidRow(
                box(title = "Nombre de patients présents par service", width = 12, status = "success", solidHeader = TRUE,
                    DTOutput("table_service"),textOutput("total"))
              )
      )
    )
  )
)

# ⚙️ Serveur
server <- function(input, output, session) {
  
  # Tableau des patients hospitalisés
  output$table_patients <- renderDT({
    datatable(lesPatients4(data), options = list(pageLength = 10))
  })
  
  # Tableau de synthèse par service
  output$table_service <- renderDT({
    datatable(patients_present_par_service(data), options = list(pageLength = 10))
  });
  output$total<-renderText({
    df<-patients_present_par_service(data)
    paste("Le nombre total de patients hospitalisés est:",sum(df$Nombre_Patients_Presents))
  })
}

# 🚀 Lancer l'application
shinyApp(ui, server)
