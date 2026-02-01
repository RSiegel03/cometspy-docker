# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    openjdk-11-jre \
    wget \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Upgrade pip
RUN pip3 install --upgrade pip setuptools wheel

# Install Jupyter stack FIRST (before other packages)
RUN pip3 install --no-cache-dir \
    jupyter \
    jupyterlab \
    notebook \
    ipykernel \
    ipython


# Register Jupyter kernel properly
RUN python3 -m ipykernel install --name python3 --display-name "Python 3"

# Install Python dependencies for COMETSpy (including gurobipy)
# Install scientific Python packages
RUN pip3 install --no-cache-dir \
    numpy \
    scipy \
    pandas>=1.5.0 \
    matplotlib \
    cobra \
    gurobipy

# Install COMETSpy
RUN pip3 install --no-cache-dir cometspy


# Verify Jupyter kernel is registered
RUN jupyter kernelspec list

# Copy and install COMETS from local file
WORKDIR /opt
COPY COMETS_2.11.0_linux.tar.gz /opt/COMETS_2.11.0_linux.tar.gz
RUN tar -xzf COMETS_2.11.0_linux.tar.gz && \
    mv comets_linux/comets_2.12.3 COMETS_2.11.0 && \
    rm -rf comets_linux && \
    rm COMETS_2.11.0_linux.tar.gz

# Set COMETS_HOME environment variable
ENV COMETS_HOME=/opt/COMETS_2.11.0

# Install Gurobi (full distribution)
# Copy and extract Gurobi
COPY gurobi13.0.1_linux64.tar.gz /opt/gurobi_installer.tar.gz
RUN cd /opt && \
    tar -xzf gurobi_installer.tar.gz && \
    rm gurobi_installer.tar.gz && \
    mv gurobi1301 gurobi

# Create Gurobi home directory structure
RUN mkdir -p /opt/gurobi_home

# Copy Gurobi license file
COPY gurobi.lic /opt/gurobi_home/gurobi.lic

# Link gurobi.jar to COMETS lib directory
RUN ln -s /opt/gurobi/linux64/lib/gurobi.jar /opt/COMETS_2.11.0/lib/gurobi.jar

# Set Gurobi environment variables
ENV GUROBI_HOME=/opt/gurobi/linux64
ENV GUROBI_COMETS_HOME=/opt/gurobi/linux64
ENV GRB_LICENSE_FILE=/opt/gurobi_home/gurobi.lic
ENV LD_LIBRARY_PATH="${GUROBI_HOME}/lib:${LD_LIBRARY_PATH}"

# Add COMETS bin directory to PATH
ENV PATH="${COMETS_HOME}/bin:${GUROBI_HOME}/bin:${PATH}"

# Create a workspace directory
WORKDIR /workspace

# Set the default command to bash
CMD ["/bin/bash"]
