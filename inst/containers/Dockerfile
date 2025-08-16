FROM rocker/r2u:jammy

# Install system libraries needed for geospatial work and other common R extensions.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdal-bin libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /project
COPY . /project

# Restore R packages from renv.lock (assumes renv is included in the repo)
RUN R -q -e "install.packages('renv'); renv::restore(prompt = FALSE)"

# Default command: run the full pipeline
CMD ["R", "-q", "-e", "targets::tar_make()"]