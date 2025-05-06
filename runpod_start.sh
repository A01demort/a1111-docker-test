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

# 초기 확장 설치
if [ ! -d "$EXT_DIR/adetailer" ]; then
    echo "🧱 WebUI 초기 확장 및 리포지토리 설치 중..."

    mkdir -p "$WEBUI_DIR/models/Stable-diffusion"

    git clone https://github.com/Stability-AI/generative-models.git "$REPO_DIR/generative-models"
    pip install -e "$REPO_DIR/generative-models"

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

    echo "✅ 확장 및 리포지토리 설치 완료"
fi

# 사용자 패키지 자동 재설치
if [ -f "$USER_REQUIREMENTS" ]; then
    echo "🔍 사용자 패키지 재설치 중..."
    pip install --no-cache-dir -r "$USER_REQUIREMENTS"
fi

# 현재 패키지 목록
pip freeze > /workspace/.current_installed.txt

# 기존과 다르면 저장
if ! cmp -s /workspace/.current_installed.txt "$LAST_FREEZE"; then
    echo "📝 패키지 변경 감지됨 — requirements-user.txt 자동 갱신"
    cp /workspace/.current_installed.txt "$USER_REQUIREMENTS"
    cp /workspace/.current_installed.txt "$LAST_FREEZE"
else
    echo "✅ 사용자 패키지 변경 없음"
fi

# 🔌 ReActor SFW 확장 설치 및 버그 패치
REACTOR_NAME="sd-webui-reactor-sfw"
REACTOR_URL="https://github.com/Gourieff/sd-webui-reactor-sfw.git"
REACTOR_PATH="$EXT_DIR/$REACTOR_NAME"

if [ ! -d "$REACTOR_PATH" ]; then
    echo "🧠 ReActor 확장 설치 중..."
    git clone "$REACTOR_URL" "$REACTOR_PATH"
fi

PATCH_FILE="$REACTOR_PATH/scripts/reactor_sfw.py"
if [ -f "$PATCH_FILE" ] && grep -q "def nsfw_image" "$PATCH_FILE"; then
    echo "🩹 ReActor NSFW 필터 버그 핫픽스 적용 중..."
    sed -i '/def nsfw_image/i\
import torch' "$PATCH_FILE"
    sed -i '/def nsfw_image/a\
    if torch.cuda.is_available():\n        img = img.to("cuda")' "$PATCH_FILE"
    echo "✅ 핫픽스 완료"
fi

# WebUI 실행
cd "$WEBUI_DIR"
python launch.py --xformers --listen --port 7860 --enable-insecure-extension-access
