#!/bin/bash

WEBUI_DIR="/workspace/stable-diffusion-webui"
EXT_DIR="$WEBUI_DIR/extensions/adetailer"
GEN_DIR="$WEBUI_DIR/repositories/generative-models"
ASSET_DIR="$WEBUI_DIR/repositories/stable-diffusion-webui-assets"

# 최초 설치만 수행
if [ ! -d "$EXT_DIR" ]; then
    echo "🧱 WebUI 초기 확장 및 모델 설치 시작..."

    # 모델 디렉토리 생성
    mkdir -p "$WEBUI_DIR/models/Stable-diffusion"

    # ADetailer 확장
    git clone https://github.com/Bing-su/adetailer.git "$EXT_DIR"

    # generative-models
    git clone https://github.com/Stability-AI/generative-models.git "$GEN_DIR"
    pip install -e "$GEN_DIR"

    # static 리소스
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets "$ASSET_DIR"

    # WebUI requirements 설치 (한 번만)
    cd "$WEBUI_DIR"
    pip install -r requirements.txt

    echo "✅ 확장 및 리포지토리 설치 완료"
else
    echo "📂 WebUI 확장 및 리포지토리 이미 존재 — 유지된 상태로 실행합니다"
fi

# WebUI 실행
cd "$WEBUI_DIR"
python launch.py --xformers --listen --port 7860 --enable-insecure-extension-access
