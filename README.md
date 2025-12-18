# RunPod ComfyUI Pod with VSCode

**English** | **[Français](README.fr.md)**

![RunPod ComfyUI VSCode](https://img.shields.io/badge/RunPod-Pod-blue) ![CUDA](https://img.shields.io/badge/CUDA-12.8.1-green) ![Python](https://img.shields.io/badge/Python-3.11-blue) ![ComfyUI](https://img.shields.io/badge/ComfyUI-Latest-orange)

Persistent RunPod Pod with **ComfyUI** + **VSCode (code-server)** for AI video/image generation and development.

## Why This Pod?

**Ready to go** - No dependency on public pods, your own persistent environment

**VSCode web interface** - Full IDE in your browser with terminal access

**Z-Image-Turbo ready** - 6B parameter photorealistic image generation (auto-download)

**SageAttention cached** - 10s cold start vs 2-3min compilation

**Performance optimized** - CUDA 12.8.1, tcmalloc, PyTorch nightly for RTX 5090

**Network Volume support** - Persistent models, cache, and custom nodes

## Quick Start

### 1. Pull Pre-built Image

```bash
docker pull vlop12ui/pod-comfyui-vscode:latest
```

### 2. Deploy on RunPod

1. Go to [RunPod Pods](https://www.runpod.io/console/pods)
2. Click **+ Deploy**
3. Select **GPU**: RTX 5090 or A100
4. **Container Image**: `vlop12ui/pod-comfyui-vscode:latest`
5. **Container Disk**: 20GB minimum
6. **Expose Ports**: `8080, 3000`
7. **(Optional)** Attach Network Volume
8. Click **Deploy**

### 3. Access Your Pod

Once deployed, RunPod will provide URLs:

- **VSCode**: `https://your-pod-id-8080.proxy.runpod.net`
- **ComfyUI**: `https://your-pod-id-3000.proxy.runpod.net`

No authentication required - RunPod handles security.

## Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| **CUDA** | 12.8.1-cudnn | GPU runtime |
| **Python** | 3.11 | Latest stable |
| **PyTorch** | Nightly cu128 | RTX 5090 support (sm_120) |
| **ComfyUI** | Commit 36357bb | Stable version |
| **SageAttention** | Commit 68de379 | INT8/FP16 quantized attention |
| **Z-Image-Turbo** | Latest | Text-to-image generation (auto-download) |
| **UltraSharp** | 4x upscaler | ESRGAN upscaler (67MB, included) |
| **code-server** | 4.96.2 | VSCode in browser |
| **tcmalloc** | Latest | Memory optimization |

## Features

### ComfyUI Optimizations

- ⚡ **SageAttention caching**: ~10s cold start (vs 2-3min without cache)
- 🎯 **WAN 2.2 ready**: Text-to-video and image-to-video workflows
- 🖼️ **Z-Image-Turbo auto-download**: Automatic model download to network volume (diffusion model, text encoder, VAE)
- 🔍 **UltraSharp 4x upscaler**: Pre-installed ESRGAN upscaler (67MB)
- 📋 **Example workflows**: Z-Image-Turbo with upscaling demonstration
- 🧠 **tcmalloc enabled**: Efficient memory management
- 📦 **Network Volume support**: Persistent models and cache
- 🔄 **Auto-initialization**: ComfyUI automatically copied to network volume on first run

### Development Environment

- 💻 **VSCode in browser**: Full IDE with terminal
- 🔌 **No authentication**: Secured by RunPod proxy
- 📂 **Access to /workspace**: Edit custom nodes, workflows, scripts
- 🐍 **Python 3.11 + PyTorch**: Ready for development
- 📊 **Professional logging**: Clean output with [OK]/[ERROR]/[WARN] tags and single-line progress bars

## Network Volume Structure

```
/workspace/  (mounted from /runpod-volume)
├── ComfyUI/                    # ComfyUI installation
│   ├── models/
│   │   ├── checkpoints/        # Your models (.safetensors)
│   │   ├── diffusion_models/   # Z-Image-Turbo diffusion model (auto-downloaded)
│   │   ├── clip/               # Text encoders (Qwen, auto-downloaded)
│   │   ├── vae/                # VAE models (auto-downloaded)
│   │   ├── unet/               # UNet models
│   │   ├── loras/              # LoRA models
│   │   └── upscale_models/     # UltraSharp 4x (pre-installed)
│   ├── custom_nodes/           # 16 custom nodes installed
│   ├── output/                 # Generated images/videos
│   ├── input/                  # Source images
│   └── user/default/workflows/ # Example Z-Image-Turbo workflow
├── sageattention_cache/        # SageAttention compiled cache
│   ├── SageAttention/
│   └── .commit_hash
└── your-projects/              # Your dev projects
```

## Performance

### Startup Times

- **With SageAttention cache** (Network Volume): ~10-15s
- **Without cache** (first start): ~2-3min (compilation)
- **Cache validation**: Automatic via commit hash

### Generation Times (RTX 5090)

| Workflow | Resolution | Frames | Time |
|----------|-----------|--------|------|
| WAN 2.2 t2v | 720p | 61 | ~50-55s |
| WAN 2.2 i2v | 720p | 61 | ~50-55s |
| Image gen | 1080x1920 | 1 | ~10-12s |

## Usage

### Accessing Services

1. **VSCode**: Click the `8080` port link in RunPod dashboard
   - Edit custom nodes in `/workspace/ComfyUI/custom_nodes/`
   - Create workflows
   - Python development

2. **ComfyUI**: Click the `3000` port link in RunPod dashboard
   - Load workflows
   - Generate images/videos
   - Test custom nodes

### Adding Custom Nodes

Via VSCode terminal:

```bash
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/your-custom-node.git
cd your-custom-node
pip install -r requirements.txt
```

Then restart ComfyUI (stop/start pod).

### Adding Models

Upload via VSCode file explorer or terminal:

```bash
# In /workspace/ComfyUI/models/checkpoints/
# Upload your .safetensors files
```

## Local Development

```bash
git clone https://github.com/yourusername/pod-comfyui-vscode.git
cd pod-comfyui-vscode
docker-compose up --build
```

Access:
- VSCode: http://localhost:8080
- ComfyUI: http://localhost:3000

## Troubleshooting

### SageAttention fails to compile

```bash
# In VSCode terminal or SSH
rm -rf /workspace/sageattention_cache
# Restart pod
```

### ComfyUI not loading models

Check models directory:

```bash
ls -la /workspace/ComfyUI/models/checkpoints/
```

Make sure files have correct permissions.

### Port not accessible

Verify in RunPod dashboard:
- Pod is running
- Ports 8080 and 3000 are exposed
- Click the port link (not direct IP)

## Cost Estimation

**RTX 5090** (~$0.90/hour):
- Development time: Billed per hour
- Active use recommended: 4-8 hours/day
- Cost: ~$3.60-$7.20/day for active development

**Tip**: Stop pod when not in use to save costs.

## Git Workflow

This repository uses Git Flow with two main branches:

- **`main`**: Stable production-ready images. Pull from `vlop12ui/pod-comfyui-vscode:main` or `:latest` for stable deployments.
- **`develop`**: Development branch with new features and updates. Pull from `vlop12ui/pod-comfyui-vscode:develop` for testing.

Docker images are automatically built and tagged for both branches on every push via GitHub Actions.

**Available Tags:**
- `main` / `latest` - Latest stable release
- `develop` - Latest development build
- `main-{sha}` / `develop-{sha}` - Specific commit builds
- `{date}-{sha}` - Date-tagged builds for chronological tracking

## License

AGPL-3.0 (inherited from ComfyUI)

---

**Developed for RunPod Pods**
- Base: CUDA 12.8.1 + cuDNN + Ubuntu 24.04
- Python 3.11 + PyTorch nightly
- ComfyUI + VSCode
- Optimized for RTX 5090

*Last update: December 2025*
