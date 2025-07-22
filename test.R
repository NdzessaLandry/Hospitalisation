url<-"https://docs.google.com/spreadsheets/d/1T6GJz7YVZkFwlvuOO5oVjDM5M4gFqFQpTkZVHiF4zO0/edit?gid=1553056256#gid=1553056256"


lire_toutes_les_feuilles <- function(sheet_url) {
  feuilles <- sheet_properties(sheet_url)$name
  
  # Lire chaque feuille et stocker avec son nom
  data_par_service <- lapply(feuilles, function(service) {
    df <- read_sheet(sheet_url, sheet = service)
    df$Service <- service  # Ajouter le nom du service dans les données
    df
  })
  
  names(data_par_service) <- feuilles
  return(data_par_service)
}
data<-lire_toutes_les_feuilles(url)
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
listePatient2 <- function(data_par_service) {
  colonnes_voulues <- c("Nom", "Prénom", "Date de naissance", "NIP", "Service")
  
  patients_sans_sortie <- lapply(names(data_par_service), function(service) {
    df <- data_par_service[[service]]
    
    # Nettoyage de la date de sortie
    if ("Date de sortie" %in% colnames(df)) {
      df$`Date de sortie` <- suppressWarnings(as.Date(df$`Date de sortie`))
    } else {
      df$`Date de sortie` <- as.Date(NA)
    }
    
    # Ajouter la colonne service si elle est absente
    df$Service <- service
    
    # Filtrer les patients encore hospitalisés
    df_filtre <- df[is.na(df$`Date de sortie`) | df$`Date de sortie` == "", ]
    
    # S'assurer que chaque colonne voulue est présente et bien typée
    for (col in colonnes_voulues) {
      if (!(col %in% colnames(df_filtre))) {
        df_filtre[[col]] <- NA_character_  # type character par défaut
      } else {
        # Forcer type character si ce n’est pas une date
        if (!inherits(df_filtre[[col]], "Date")) {
          df_filtre[[col]] <- as.character(df_filtre[[col]])
        }
      }
    }
    
    # Sélection finale
    df_filtre <- df_filtre[, colonnes_voulues, drop = FALSE]
    return(df_filtre)
  })
  
  resultat_final <- bind_rows(patients_sans_sortie)
  return(resultat_final)
}


listePatient <- function(data_par_service) {
  patients_sans_sortie <- list()
  
  for (i in seq_along(data_par_service)) {
    df <- data_par_service[[i]]
    
    if ("Date de sortie" %in% colnames(df)) {
      df$`Date de sortie` <- suppressWarnings(as.Date(df$`Date de sortie`, format = "%d/%m/%Y"))
      df_filtre <- df[is.na(df$`Date de sortie`), ]
      
      # Sélectionner explicitement les colonnes par nom
      noms_disponibles <- intersect(c("Nom", "Prénom", "Date d'entrée"), colnames(df_filtre))
      df_filtre <- df_filtre[, c(3,2,1), drop = FALSE]
      
      # Ajouter colonne service
      df_filtre$Service <- names(data_par_service)[i]
      
      patients_sans_sortie[[i]] <- df_filtre
    }
  }
  
  # Rbind sécurisé : ajoute des colonnes manquantes si besoin
  resultat_final <- bind_rows(patients_sans_sortie)
  return(resultat_final)
}
lire_toutes_les_feuilles2 <- function(sheet_url) {
  feuilles <- sheet_properties(sheet_url)$name
  
  data_par_service <- lapply(feuilles, function(service) {
    df <- read_sheet(sheet_url, sheet = service)
    
    # Forcer les colonnes de date à un type uniforme (si présentes)
    cols_dates <- c("Date d'entrée", "Date de sortie")
    for (col in cols_dates) {
      if (col %in% colnames(df)) {
        df[[col]] <- suppressWarnings(as.Date(df[[col]]))  # force Date, même si vide
      }
    }
    
    df$Service <- service  # Ajouter le nom du service
    df
  })
  
  names(data_par_service) <- feuilles
  return(data_par_service)
}

lire_toutes_les_feuilles3 <- function(sheet_url) {
  feuilles <- sheet_properties(sheet_url)$name
  
  data_par_service <- lapply(feuilles, function(service) {
    df <- read_sheet(sheet_url, sheet = service)
    
    # Si df est vide, crée un tibble avec colonnes au bon type mais 0 lignes
    if (nrow(df) == 0) {
      # Par exemple, spécifie explicitement les colonnes attendues et leur type
      colonnes_attendues <- c("Date d'entrée", "NIP", "Noms et Prénoms", "Sexe", "Age", 
                              "Telephone", "Batiment", "Salle", "Date de sortie")
      df <- tibble::as_tibble(setNames(replicate(length(colonnes_attendues), logical(0), simplify = FALSE), colonnes_attendues))
    } else {
      # Sinon, convertir les dates en Date
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
lesPatients4 <- function(data_par_service) {
  colonnes_voulues <- c("Noms et Prénoms", "Date d'entrée", "NIP", "Service")
  
  patients_sans_sortie <- lapply(names(data_par_service), function(service) {
    df <- data_par_service[[service]]
    
    # Ignorer les feuilles vides
    if (nrow(df) == 0) return(NULL)
    
    # Vérifier si "Date de sortie" existe, sinon créer colonne vide
    if (!"Date de sortie" %in% colnames(df)) {
      df$`Date de sortie` <- as.Date(NA)
    } else {
      df$`Date de sortie` <- suppressWarnings(as.Date(df$`Date de sortie`))
    }
    
    # Ajouter la colonne "Service" si elle n'existe pas
    df$Service <- service
    
    # Garder uniquement les patients encore hospitalisés
    df_filtre <- df[is.na(df$`Date de sortie`) | df$`Date de sortie` == "", ]
    
    # Si aucun patient filtré, on ne garde pas ce service non plus
    if (nrow(df_filtre) == 0) return(NULL)
    
    # Ajouter les colonnes manquantes et forcer le type à character
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
  
  # Supprimer les NULL
  patients_sans_sortie <- Filter(Negate(is.null), patients_sans_sortie)
  
  # Fusionner proprement
  resultat_final <- bind_rows(patients_sans_sortie)
  return(resultat_final)
}



