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
    VSCODE_PORT=8080 \
    CHECK_MODELS=true

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
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --pre torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/nightly/cu128 \
    && rm -rf /tmp/* /var/tmp/*

# Install code-server (VSCode web)
ARG CODE_SERVER_VERSION=4.96.2
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${CODE_SERVER_VERSION}

# Create working directory
WORKDIR /app

# Clone ComfyUI (pinned version for stability)
ARG COMFYUI_COMMIT=36357bb
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui && \
    cd comfyui && \
    git reset --hard ${COMFYUI_COMMIT}

# Install ComfyUI dependencies
RUN --mount=type=cache,target=/root/.cache/pip \
    cd comfyui && pip install -r requirements.txt \
    && rm -rf /tmp/* /var/tmp/*

# Install ComfyUI custom nodes - Batch 1 (lightweight)
RUN cd comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone --depth 1 https://github.com/theUpsider/ComfyUI-Logic.git && \
    git clone --depth 1 https://github.com/chrisgoringe/cg-use-everywhere.git && \
    git clone --depth 1 https://github.com/chrisgoringe/cg-image-picker.git && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git && \
    git clone --depth 1 https://github.com/Jordach/comfy-plasma.git && \
    git clone --depth 1 https://github.com/ClownsharkBatwing/RES4LYF.git && \
    git clone --depth 1 https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git && \
    rm -rf /tmp/* /var/tmp/*

# Install ComfyUI custom nodes - Batch 2 (medium)
RUN cd comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone --depth 1 https://github.com/cubiq/ComfyUI_essentials.git && \
    git clone --depth 1 https://github.com/Jonseed/ComfyUI-Detail-Daemon.git && \
    git clone --depth 1 https://github.com/bash-j/mikey_nodes.git && \
    git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    rm -rf /tmp/* /var/tmp/*

# Install ComfyUI custom nodes - Batch 3 (heavy, without models download)
RUN cd comfyui/custom_nodes && \
    git clone --depth 1 --recursive https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git && \
    git clone --depth 1 https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone --depth 1 https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/shadowcz007/comfyui-mixlab-nodes.git && \
    rm -rf /tmp/* /var/tmp/*
# Temporarily disabled LayerStyle nodes (require opencv-contrib with cv2.ximgproc)
# git clone --depth 1 https://github.com/chflame163/ComfyUI_LayerStyle.git && \
# git clone --depth 1 https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git && \

# Install ComfyUI custom nodes - Batch 4 (Impact Pack - downloads models)
# Skip model downloads by setting environment variable
RUN cd comfyui/custom_nodes && \
    export SKIP_MODEL_DOWNLOAD=1 && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git && \
    rm -rf /tmp/* /var/tmp/*

# Install requirements for ALL custom nodes in one layer (faster build)
RUN --mount=type=cache,target=/root/.cache/pip \
    cd /app && \
    for dir in /app/comfyui/custom_nodes/*; do \
        if [ -f "$dir/requirements.txt" ]; then \
            echo "Installing requirements for $(basename $dir)..."; \
            pip install -r "$dir/requirements.txt" || true; \
        fi; \
        if [ -f "$dir/install.py" ]; then \
            echo "Running install.py for $(basename $dir)..."; \
            cd "$dir" && python install.py && cd /app || true; \
        fi; \
    done \
    && rm -rf /tmp/* /var/tmp/* \
    && find /app/comfyui/custom_nodes -name "*.pth" -size +100M -delete \
    && find /app/comfyui/custom_nodes -name "*.safetensors" -size +100M -delete

# Install additional useful packages
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    jupyter \
    ipython \
    matplotlib \
    pandas \
    opencv-python \
    pillow \
    scikit-image \
    scipy \
    tqdm \
    && rm -rf /tmp/* /var/tmp/*

# Copy initialization and startup scripts
COPY init.sh /app/init.sh
COPY start.sh /app/start.sh
RUN chmod +x /app/init.sh /app/start.sh

# Copy code-server configuration
COPY config/code-server-config.yaml /root/.config/code-server/config.yaml

# Copy VSCode settings (dark theme, etc.)
RUN mkdir -p /root/.local/share/code-server/User
COPY config/vscode-settings.json /root/.local/share/code-server/User/settings.json

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
