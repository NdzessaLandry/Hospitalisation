# Image officielle R avec Shiny
FROM rocker/shiny:latest

# Installer les packages système nécessaires
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier tous les fichiers de l'app dans le conteneur
COPY . /srv/shiny-server/

# Installer les packages R (à adapter selon ton app)
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'shinymanager', 'DT', 'dplyr', 'googlesheets4', 'bslib', 'tibble'))"

# Créer un utilisateur non-root
RUN useradd -m shinyuser

# Donner accès à l’utilisateur
RUN chown -R shinyuser /srv/shiny-server

# Utiliser shinyuser au lieu de root
USER shinyuser

# Exposer le port 3838 utilisé par Shiny
EXPOSE 3838

# Lancer l'application automatiquement
CMD ["/usr/bin/shiny-server"]
