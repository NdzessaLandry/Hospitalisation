#  Chargement des packages
library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(googlesheets4)
library(tibble)
library(bslib)
library(shinymanager)

credentials <- data.frame(
  user = c("hopital central yaounde", "user1"),
  password = c("hopital central yaounde", "user123"), 
  stringsAsFactors = FALSE
)

url <- "https://docs.google.com/spreadsheets/d/1T6GJz7YVZkFwlvuOO5oVjDM5M4gFqFQpTkZVHiF4zO0/edit?usp=sharing"


lire_toutes_les_feuilles <- function(sheet_url) {
  feuilles <- sheet_properties(sheet_url)$name
  
  data_par_service <- lapply(feuilles, function(service) {
    df <- read_sheet(sheet_url, sheet = service)
    
    if (nrow(df) == 0) {
      colonnes_attendues <- c("Date d'entrée", "NIP", "Noms et Prénoms", "Sexe", "Age", 
                              "Telephone", "Batiment", "Salle", "Date de sortie")
      df <- tibble::as_tibble(setNames(replicate(length(colonnes_attendues), logical(0), simplify = FALSE), colonnes_attendues))
    } else {
      cols_dates <- c("Date d'entrée", "Date de sortie")
      for (col in cols_dates) {
        if (col %in% colnames(df)) {
          df[[col]] <- suppressWarnings(as.Date(df[[col]]))
        }
      }
    }
    
    df$Service <- service
    df
  })
  
  names(data_par_service) <- feuilles
  return(data_par_service)
}

#  Patients hospitalisés
lesPatients <- function(data_par_service) {
  colonnes_voulues <- c("Noms et Prénoms", "Date d'entrée", "NIP", "Service")
  
  patients_sans_sortie <- lapply(names(data_par_service), function(service) {
    df <- data_par_service[[service]]
    if (nrow(df) == 0) return(NULL)
    
    if (!"Date de sortie" %in% colnames(df)) {
      df$`Date de sortie` <- as.Date(NA)
    } else {
      df$`Date de sortie` <- suppressWarnings(as.Date(df$`Date de sortie`))
    }
    
    df$Service <- service
    df_filtre <- df[is.na(df$`Date de sortie`) | df$`Date de sortie` == "", ]
    if (nrow(df_filtre) == 0) return(NULL)
    
    for (col in colonnes_voulues) {
      if (!col %in% colnames(df_filtre)) {
        df_filtre[[col]] <- NA_character_
      } else if (!inherits(df_filtre[[col]], "Date")) {
        df_filtre[[col]] <- as.character(df_filtre[[col]])
      }
    }
    
    df_filtre <- df_filtre[, colonnes_voulues, drop = FALSE]
    return(df_filtre)
  })
  
  patients_sans_sortie <- Filter(Negate(is.null), patients_sans_sortie)
  bind_rows(patients_sans_sortie)
}

# Nombre de patients par service
patients_present_par_service <- function(data_par_service) {
  resultats <- lapply(names(data_par_service), function(service) {
    donnees <- data_par_service[[service]]
    if (!"Date de sortie" %in% colnames(donnees)) {
      return(tibble(Service = service, Nombre_Patients_Presents = NA))
    }
    n_present <- donnees %>%
      filter(is.na(`Date de sortie`) | `Date de sortie` == "") %>%
      nrow()
    tibble(Service = service, Nombre_Patients_Presents = n_present)
  })
  
  bind_rows(resultats)
}

# Lecture des données (une seule fois)
data <- lire_toutes_les_feuilles(url)

# Thème rose Windows 11
mon_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#da77f2",
  base_font = font_google("Segoe UI")
)

# Interface sécurisée
ui <- secure_app(
  dashboardPage(
    dashboardHeader(title = "Suivi des Hospitalisations"),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Tableau des patients", tabName = "table", icon = icon("table")),
        menuItem("Visualisation par service", tabName = "service", icon = icon("chart-bar"))
      )
    ),
    dashboardBody(
      theme = mon_theme,
      tabItems(
        tabItem(tabName = "table",
                fluidRow(
                  box(title = "Liste des patients hospitalisés", width = 12, status = "primary", solidHeader = TRUE,
                      DTOutput("table_patients"))
                )
        ),
        tabItem(tabName = "service",
                fluidRow(
                  box(title = "Patients présents par service", width = 12, status = "success", solidHeader = TRUE,
                      DTOutput("table_service"),
                      br(),
                      textOutput("total"))
                )
        )
      )
    )
  )
)

# Serveur
server <- function(input, output, session) {
  
  # Authentification obligatoire
  res_auth <- secure_server(
    check_credentials = check_credentials(
      "auth_db.sqlite",
      passphrase = "hopital central de yaounde"
    )
  )
  
  output$table_patients <- renderDT({
    datatable(lesPatients(data), options = list(pageLength = 10))
  });
  output$table_service <- renderDT({
    datatable(patients_present_par_service(data), options = list(pageLength = 10))
  });
  output$total <- renderText({
    df <- patients_present_par_service(data)
    total <- sum(df$Nombre_Patients_Presents, na.rm = TRUE)
    paste("Nombre total de patients hospitalisés : ", total)
  });
}

#  Lancer l'application
shinyApp(ui, server)
