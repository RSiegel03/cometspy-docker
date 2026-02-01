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
    openjdk-11-jdk \
    wget \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Upgrade pip
RUN pip3 install --upgrade pip setuptools wheel

# Install Jupyter stack FIRST
RUN pip3 install --no-cache-dir \
    jupyter \
    jupyterlab \
    notebook \
    ipykernel \
    ipython

# Register Jupyter kernel properly
RUN python3 -m ipykernel install --name python3 --display-name "Python 3"

# Install Python dependencies for COMETSpy
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

# === GUROBI INSTALLATION ===
# Explanation: Extract to /opt/gurobi to match COMETSpy's hardcoded defaults
# COMETSpy expects Gurobi to be in /opt/gurobi/linux64/
WORKDIR /opt

COPY gurobi9.5.2_linux64.tar.gz /opt/gurobi_installer.tar.gz

# Explanation: Extract and rename to 'gurobi' (not 'gurobi1301')
# This matches what COMETSpy looks for by default
RUN tar -xzf gurobi_installer.tar.gz && \
    rm gurobi_installer.tar.gz && \
    mv gurobi952 gurobi

# Explanation: Verify the directory structure
RUN echo "=== Checking Gurobi structure ===" && \
    ls -la /opt/gurobi/ && \
    echo "=== Looking for gurobi.jar ===" && \
    find /opt/gurobi -name "gurobi*.jar"

# Create directory for license file
RUN mkdir -p /opt/gurobi_home

# Copy Gurobi license file
COPY gurobi.lic /opt/gurobi_home/gurobi.lic

# Explanation: Use /opt/gurobi/linux64 to match COMETSpy's expectations
ENV GUROBI_HOME=/opt/gurobi/linux64
ENV GUROBI_COMETS_HOME=/opt/gurobi/linux64
ENV GRB_LICENSE_FILE=/opt/gurobi_home/gurobi.lic
ENV LD_LIBRARY_PATH="${GUROBI_HOME}/lib:${LD_LIBRARY_PATH}"
ENV PATH="${GUROBI_HOME}/bin:${PATH}"

# === COMETS INSTALLATION ===
WORKDIR /opt

COPY COMETS_2.11.0_linux.tar.gz /opt/COMETS_2.11.0_linux.tar.gz
RUN tar -xzf COMETS_2.11.0_linux.tar.gz && \
    mv comets_linux/comets_2.12.3 COMETS_2.11.0 && \
    rm -rf comets_linux && \
    rm COMETS_2.11.0_linux.tar.gz

ENV COMETS_HOME=/opt/COMETS_2.11.0

# Explanation: Create symbolic link from COMETS lib to actual gurobi.jar location
# The jar is in /opt/gurobi/linux64/lib/gurobi.jar after our rename
RUN echo "=== Creating symbolic link to gurobi.jar ===" && \
    GUROBI_JAR=$(find /opt/gurobi -name "gurobi.jar" | head -1) && \
    echo "Found Gurobi JAR at: $GUROBI_JAR" && \
    ln -sf $GUROBI_JAR /opt/COMETS_2.11.0/lib/gurobi.jar && \
    echo "=== Verifying link ===" && \
    ls -la /opt/COMETS_2.11.0/lib/gurobi.jar && \
    echo "=== Testing link target ===" && \
    ls -la $(readlink -f /opt/COMETS_2.11.0/lib/gurobi.jar)

# Add COMETS bin directory to PATH
ENV PATH="${COMETS_HOME}/bin:${PATH}"

# Explanation: Set CLASSPATH explicitly for Java
ENV CLASSPATH="${COMETS_HOME}/lib/gurobi.jar:${COMETS_HOME}/bin/comets.jar:${CLASSPATH}"

# Create a workspace directory
WORKDIR /workspace

# Set the default command to bash
CMD ["/bin/bash"]
