library(shinymanager)

# Création d'une base de données utilisateurs avec mdp cryptés
credentials <- data.frame(
  user = c("Directeur", "infirmier", "visiteur"),
  password = c("HopitalCentralYaounde", "medic2024", "demo"), # mots de passe
  admin = c(TRUE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

# Hasher les mots de passe (à faire une seule fois !)
credentials <- shinymanager::create_db(
  credentials_data = credentials,
  sqlite_path = "C:\\Users\\DELL\\Documents\\SuiviDesHospitalisations\\auth_db.sqlite", # fichier de base SQLite stocké localement
  passphrase = "hopital central de yaounde"  # phrase secrète de chiffrement
)
