# Use an official Ubuntu as the base image
FROM ubuntu:20.04

# Set environment variables to make the installation non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Update the repository sources to use security.ubuntu.com and clean cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    sed -i 's|http://archive.ubuntu.com/ubuntu|http://security.ubuntu.com/ubuntu|g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y --fix-missing \
    wget \
    bzip2 \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    build-essential

# Create directory for Miniconda
RUN mkdir -p /opt/miniconda3

# Install Miniconda with update option (-u)
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /opt/miniconda3/miniconda.sh && \
    bash /opt/miniconda3/miniconda.sh -b -u -p /opt/miniconda3 && \
    rm /opt/miniconda3/miniconda.sh

# Set the path to conda
ENV PATH="/opt/miniconda3/bin:$PATH"

# Initialize conda in bash shell
RUN /opt/miniconda3/bin/conda init bash

# Create a new conda environment for R and activate it
RUN /opt/miniconda3/bin/conda create -n r-environment r-base -y

# Activate the environment in bashrc
RUN echo "source /opt/miniconda3/bin/activate r-environment" >> ~/.bashrc

# Set bash as the default shell and initialize conda
SHELL ["/bin/bash", "-c"]

# Install required R packages inside the conda environment
RUN conda run -n r-environment R -e "install.packages(c('data.table', 'dplyr', 'sqldf', 'ggplot2', 'wesanderson'), repos='https://cloud.r-project.org/')"
RUN apt-get update && apt-get install -y \
    libx11-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev libpng-dev
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "install.packages(c('ggtext', 'ggrepel', 'ggforce', 'ggsci', 'ggpubr'), repos='https://cloud.r-project.org/')"
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "install.packages(c('ggplotify', 'ggimage', 'ggthemes', 'ggdist'), repos='https://cloud.r-project.org/')"
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "install.packages(c('ggprism', 'ggpattern', 'ggalt', 'ggforce'), repos='https://cloud.r-project.org/')"
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "install.packages(c('ggrepel', 'ggtext', 'ggforce', 'ggsci', 'ggpubr'), repos='https://cloud.r-project.org/')"
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "install.packages(c('ggplot2', 'ggthemes', 'ggdist'), repos='https://cloud.r-project.org/')"
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "install.packages(c('ggprism', 'ggpattern', 'ggalt'), repos='https://cloud.r-project.org/')"
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
RUN /opt/miniconda3/bin/conda run -n r-environment R -e "remotes::install_github('Khunanon-Chanasongkhram/DisVar', dependencies=TRUE, upgrade=TRUE)"

# Set the default command to activate the conda environment and run R
CMD ["conda", "run", "-n", "r-environment", "bash"]
