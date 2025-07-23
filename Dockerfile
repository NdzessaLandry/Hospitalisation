FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /srv/shiny-server/

RUN R -e "install.packages(c('shiny', 'shinydashboard', 'shinymanager', 'DT', 'dplyr', 'googlesheets4', 'bslib', 'tibble'))"

# Donne la propriété des fichiers à shiny
RUN chown -R shiny:shiny /srv/shiny-server

# Expose le port 3838
EXPOSE 3838

# Lance shiny-server sous l'utilisateur shiny (par défaut)
USER shiny

CMD ["/usr/bin/shiny-server"]
