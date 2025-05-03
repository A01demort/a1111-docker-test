#!/bin/bash

WEBUI_DIR="/workspace/stable-diffusion-webui"
INSTALL_FLAG="$WEBUI_DIR/launch.py"

# WebUI 디렉토리가 존재하지 않으면 설치
if [ ! -f "$INSTALL_FLAG" ]; then
    echo "🧱 WebUI 최초 설치 중..."

    # WebUI 설치
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$WEBUI_DIR"
    mkdir -p "$WEBUI_DIR/models/Stable-diffusion"

    # 기본 확장 및 리포지토리 설치
    git clone https://github.com/Bing-su/adetailer.git "$WEBUI_DIR/extensions/adetailer"
    git clone https://github.com/Stability-AI/generative-models.git "$WEBUI_DIR/repositories/generative-models"
    pip install -e "$WEBUI_DIR/repositories/generative-models"

    # static 리소스
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets "$WEBUI_DIR/repositories/stable-diffusion-webui-assets"

    # Python requirements
    cd "$WEBUI_DIR"
    pip install -r requirements.txt

    echo "✅ 최초 설치 완료"
else
    echo "📂 WebUI 디렉토리 이미 존재 — 추가 확장 포함 모두 생존 유지됨"
fi

# 실행
cd "$WEBUI_DIR"
python launch.py --xformers --listen --port 7860 --enable-insecure-extension-access
