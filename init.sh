#!/bin/bash
# Initialization script for RunPod ComfyUI Pod with VSCode
# Handles SageAttention compilation with network volume caching

set -e

echo "🚀 Starting initialization..."

# SageAttention installation with network volume caching
SAGE_CACHE_DIR="/workspace/sageattention_cache"
SAGE_COMMIT="68de379"
SAGE_COMMIT_FILE="$SAGE_CACHE_DIR/.commit_hash"

compile_sageattention() {
    echo "🔨 Compiling SageAttention from source (commit $SAGE_COMMIT)..."

    # Pre-flight check: Verify PyTorch can access CUDA
    echo "🔍 Pre-flight check: Testing PyTorch CUDA access..."
    if ! python -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'; print(f'✅ CUDA available: {torch.cuda.get_device_name(0)}')"; then
        echo "❌ ERROR: PyTorch cannot access CUDA"
        echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
        echo "CUDA_HOME: $CUDA_HOME"
        return 1
    fi

    # Clone and build
    cd /tmp
    if [ -d "SageAttention" ]; then
        rm -rf SageAttention
    fi

    git clone https://github.com/thu-ml/SageAttention.git
    cd SageAttention
    git reset --hard $SAGE_COMMIT

    # Set build flags for optimal compilation
    export EXT_PARALLEL=4
    export NVCC_APPEND_FLAGS="--threads 8"
    export MAX_JOBS=32

    echo "🔧 Building CUDA extensions..."
    # Step 1: Build extensions in-place
    if ! python setup.py build_ext --inplace > /tmp/sage_build.log 2>&1; then
        echo "❌ ERROR: SageAttention build_ext failed"
        cat /tmp/sage_build.log
        return 1
    fi

    echo "📦 Installing SageAttention package..."
    # Step 2: Install package (normal install, NOT editable)
    if ! pip install --no-build-isolation --no-deps . >> /tmp/sage_build.log 2>&1; then
        echo "❌ ERROR: SageAttention install failed"
        cat /tmp/sage_build.log
        return 1
    fi

    # Verify installation
    echo "✅ Verifying SageAttention installation..."
    if ! python -c "import sageattention; print(f'✅ SageAttention version: {sageattention.__version__ if hasattr(sageattention, \"__version__\") else \"installed\"}')" 2>/dev/null; then
        echo "❌ ERROR: SageAttention import failed after installation"
        return 1
    fi

    # Cache the successful build
    echo "💾 Caching SageAttention build to network volume..."
    mkdir -p "$SAGE_CACHE_DIR"
    cp -r /tmp/SageAttention "$SAGE_CACHE_DIR/"
    echo "$SAGE_COMMIT" > "$SAGE_COMMIT_FILE"

    echo "✅ SageAttention compilation and caching completed"
    return 0
}

# Check for cached build
if [ -d "$SAGE_CACHE_DIR/SageAttention" ] && [ -f "$SAGE_COMMIT_FILE" ]; then
    CACHED_COMMIT=$(cat "$SAGE_COMMIT_FILE")

    if [ "$CACHED_COMMIT" = "$SAGE_COMMIT" ]; then
        echo "📦 Found valid SageAttention cache (commit $CACHED_COMMIT)"
        echo "⚡ Installing from cache (~10 seconds)..."

        cd "$SAGE_CACHE_DIR/SageAttention"

        # Install from cache
        if pip install --no-build-isolation --no-deps . > /tmp/sage_cache_install.log 2>&1; then
            # Verify cached installation works
            if python -c "import sageattention" 2>/dev/null; then
                echo "✅ SageAttention installed from cache successfully"
            else
                echo "⚠️  Cached installation failed import test, rebuilding..."
                compile_sageattention || exit 1
            fi
        else
            echo "⚠️  Cache installation failed, rebuilding from source..."
            compile_sageattention || exit 1
        fi
    else
        echo "⚠️  Cache commit mismatch (cached: $CACHED_COMMIT, expected: $SAGE_COMMIT)"
        echo "🔄 Rebuilding SageAttention..."
        compile_sageattention || exit 1
    fi
else
    echo "📭 No SageAttention cache found"
    echo "🔨 Compiling from source (this will take 2-3 minutes)..."
    compile_sageattention || exit 1
fi

# Z-Image-Turbo model checking and downloading
if [ "${CHECK_MODELS:-true}" = "true" ]; then
    echo "🔍 Checking Z-Image-Turbo models..."

    # Determine ComfyUI location (same logic as start.sh)
    if [ -d "/app/comfyui" ]; then
        COMFYUI_DIR="/app/comfyui"
    elif [ -d "/workspace/ComfyUI" ]; then
        COMFYUI_DIR="/workspace/ComfyUI"
    else
        echo "⚠️  ComfyUI directory not found, skipping model check"
    fi

    if [ -n "$COMFYUI_DIR" ]; then
        # Define model paths
        DIFFUSION_MODEL="$COMFYUI_DIR/models/checkpoints/z_image_turbo_bf16.safetensors"
        TEXT_ENCODER="$COMFYUI_DIR/models/clip/qwen_3_4b.safetensors"
        VAE_MODEL="$COMFYUI_DIR/models/vae/ae.safetensors"

        MODELS_MISSING=false

        # Check diffusion model
        if [ ! -f "$DIFFUSION_MODEL" ]; then
            echo "📥 Downloading Z-Image-Turbo diffusion model..."
            mkdir -p "$COMFYUI_DIR/models/checkpoints"
            wget -q --show-progress -O "$DIFFUSION_MODEL" \
                "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
                || { echo "❌ Failed to download diffusion model"; MODELS_MISSING=true; }
        else
            echo "✅ Diffusion model found: z_image_turbo_bf16.safetensors"
        fi

        # Check text encoder
        if [ ! -f "$TEXT_ENCODER" ]; then
            echo "📥 Downloading Z-Image-Turbo text encoder..."
            mkdir -p "$COMFYUI_DIR/models/clip"
            wget -q --show-progress -O "$TEXT_ENCODER" \
                "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
                || { echo "❌ Failed to download text encoder"; MODELS_MISSING=true; }
        else
            echo "✅ Text encoder found: qwen_3_4b.safetensors"
        fi

        # Check VAE
        if [ ! -f "$VAE_MODEL" ]; then
            echo "📥 Downloading Z-Image-Turbo VAE..."
            mkdir -p "$COMFYUI_DIR/models/vae"
            wget -q --show-progress -O "$VAE_MODEL" \
                "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors" \
                || { echo "❌ Failed to download VAE"; MODELS_MISSING=true; }
        else
            echo "✅ VAE found: ae.safetensors"
        fi

        if [ "$MODELS_MISSING" = "false" ]; then
            echo "✅ All Z-Image-Turbo models are available"
        else
            echo "⚠️  Some models failed to download, but continuing..."
        fi
    fi
else
    echo "⏭️  Model checking disabled (CHECK_MODELS=false)"
fi

echo "✅ Initialization completed successfully"
exit 0
