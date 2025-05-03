#!/bin/bash

WEBUI_DIR="/workspace/stable-diffusion-webui"
EXT_DIR="$WEBUI_DIR/extensions"
REPO_DIR="$WEBUI_DIR/repositories"
ASSET_DIR="$REPO_DIR/stable-diffusion-webui-assets"
USER_REQUIREMENTS="/workspace/requirements-user.txt"
LAST_FREEZE="/workspace/.last_installed.txt"

declare -A EXTENSIONS=(
  [adetailer]="https://github.com/Bing-su/adetailer"
  [aspect-ratio-helper]="https://github.com/thomasasfk/sd-webui-aspect-ratio-helper"
  [tagcomplete]="https://github.com/DominikDoom/a1111-sd-webui-tagcomplete"
  [dynamic-thresholding]="https://github.com/mcmonkeyprojects/sd-dynamic-thresholding.git"
  [ultimate-upscale]="https://github.com/Coyote-A/ultimate-upscale-for-automatic1111"
  [canvas-zoom]="https://github.com/richrobber2/canvas-zoom.git"
  [segment-anything]="https://github.com/continue-revolution/sd-webui-segment-anything.git"
  [civitai-helper]="https://github.com/zixaphir/Stable-Diffusion-Webui-Civitai-Helper.git"
  [controlnet]="https://github.com/Mikubill/sd-webui-controlnet.git"
)

# ✅ 확장 기능 설치
if [ ! -d "$EXT_DIR/adetailer" ]; then
    echo "🧱 WebUI 확장 및 리포지토리 설치 중..."

    mkdir -p "$WEBUI_DIR/models/Stable-diffusion"

    # 필수 리포지토리
    git clone https://github.com/Stability-AI/generative-models.git "$REPO_DIR/generative-models"
    pip install -e "$REPO_DIR/generative-models"

    # static asset
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets "$ASSET_DIR"

    for name in "${!EXTENSIONS[@]}"; do
        dst="$EXT_DIR/$name"
        repo="${EXTENSIONS[$name]}"
        if [ ! -d "$dst" ]; then
            echo "🔗 설치 중: $name"
            git clone "$repo" "$dst"
        fi
    done

    cd "$WEBUI_DIR"
    pip install -r requirements.txt

    echo "✅ 확장 설치 완료"
fi

# ✅ 사용자 패키지 자동 설치
if [ -f "$USER_REQUIREMENTS" ]; then
    echo "🔍 사용자 패키지 재설치 중..."
    pip install --no-cache-dir -r "$USER_REQUIREMENTS"
fi

# ✅ pip freeze 상태 추적
pip freeze > /workspace/.current_installed.txt
if ! cmp -s /workspace/.current_installed.txt "$LAST_FREEZE"; then
    cp /workspace/.current_installed.txt "$USER_REQUIREMENTS"
    cp /workspace/.current_installed.txt "$LAST_FREEZE"
fi

# ✅ PYTHONPATH에 확장 scripts 경로 등록 (중요!!)
export PYTHONPATH=$PYTHONPATH:\
$EXT_DIR/sd-webui-controlnet/scripts:\
$EXT_DIR/sd-webui-segment-anything/scripts:\
$EXT_DIR/a1111-sd-webui-tagcomplete/scripts

echo "🔧 PYTHONPATH 등록 완료"

# ✅ WebUI 실행
cd "$WEBUI_DIR"
python launch.py --xformers --listen --enable-insecure-extension-access
