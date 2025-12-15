# RunPod ComfyUI Pod with VSCode
# Optimized for RTX 5090 with CUDA 12.8.1, SageAttention, and code-server
# Base: Ubuntu 24.04 + CUDA 12.8.1-cudnn

FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

# Metadata
LABEL maintainer="ComfyUI Pod VSCode"
LABEL description="RunPod Pod with ComfyUI, VSCode (code-server), SageAttention, and performance optimizations"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH="${CUDA_HOME}/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}" \
    TORCH_CUDA_ARCH_LIST="8.9+PTX" \
    COMFYUI_PORT=3000 \
    VSCODE_PORT=8080

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    # Python 3.11
    software-properties-common \
    # Git and tools
    git \
    git-lfs \
    wget \
    curl \
    unzip \
    nano \
    vim \
    # Media libraries
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    # Network tools
    openssh-server \
    rsync \
    # Performance optimization
    google-perftools \
    libtcmalloc-minimal4 \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11 from deadsnakes PPA
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-dev \
        python3.11-venv \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Upgrade pip
RUN python3 -m pip install --upgrade --ignore-installed pip setuptools wheel

# Install PyTorch nightly with CUDA 12.8 support (RTX 5090 sm_120)
RUN pip install --pre torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/nightly/cu128

# Install code-server (VSCode web)
ARG CODE_SERVER_VERSION=4.96.2
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${CODE_SERVER_VERSION}

# Create working directory
WORKDIR /app

# Clone ComfyUI (pinned version for stability)
ARG COMFYUI_COMMIT=0.4.0
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui && \
    cd comfyui && \
    git reset --hard ${COMFYUI_COMMIT}

# Install ComfyUI dependencies
RUN cd comfyui && pip install -r requirements.txt

# Install custom nodes dependencies
RUN cd comfyui/custom_nodes && \
    # ComfyUI Manager
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    # Install WAN 2.2 dependencies if needed
    pip install accelerate diffusers timm einops

# Install additional useful packages
RUN pip install \
    jupyter \
    ipython \
    matplotlib \
    pandas \
    opencv-python \
    pillow \
    scikit-image \
    scipy \
    tqdm

# Copy initialization and startup scripts
COPY init.sh /app/init.sh
COPY start.sh /app/start.sh
RUN chmod +x /app/init.sh /app/start.sh

# Copy code-server configuration
COPY config/code-server-config.yaml /root/.config/code-server/config.yaml

# Expose ports
# 8080: code-server (VSCode)
# 3000: ComfyUI
# 22: SSH
EXPOSE 8080 3000 22

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Start services
CMD ["/app/start.sh"]
