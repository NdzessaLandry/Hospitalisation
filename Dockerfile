# Base image officielle avec R + Shiny
FROM rocker/shiny:4.3.1

# Installer dépendances système
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libicu-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev

# Copier les fichiers dans le conteneur
COPY . /srv/shiny-server/

# Installer les packages R nécessaires
RUN R -e "install.packages('remotes')"
RUN R -e "source('/srv/shiny-server/packages.R')"

# Exposer le port
EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
