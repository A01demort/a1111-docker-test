#!/bin/bash

WEBUI_DIR="/workspace/stable-diffusion-webui"
EXT_DIR="$WEBUI_DIR/extensions"
REPO_DIR="$WEBUI_DIR/repositories"
GEN_REPO_DST="$REPO_DIR/generative-models-lib"
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

echo "🧹 캐시 및 환경 초기화 중..."
find "$WEBUI_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find "$WEBUI_DIR" -name "*.pyc" -delete 2>/dev/null
rm -rf ~/.nv 2>/dev/null || true

# ✅ WebUI 클론
if [ ! -d "$WEBUI_DIR/.git" ]; then
    echo "📥 WebUI 클론 중..."
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$WEBUI_DIR"
fi

# ✅ 확장 및 리포지토리 설치 (최초 1회)
if [ ! -d "$EXT_DIR/adetailer" ]; then
    echo "📦 확장 및 리포지토리 설치 시작..."
    mkdir -p "$WEBUI_DIR/models/Stable-diffusion"

    if [ ! -d "$GEN_REPO_DST" ]; then
        git clone https://github.com/Stability-AI/generative-models.git "$GEN_REPO_DST"
        pip install -e "$GEN_REPO_DST"
    fi

    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets "$ASSET_DIR"

    for name in "${!EXTENSIONS[@]}"; do
        dst="$EXT_DIR/$name"
        repo="${EXTENSIONS[$name]}"
        if [ ! -d "$dst" ]; then
            echo "🔗 [$name] 설치 중..."
            git clone "$repo" "$dst"
        fi
    done

    echo "✅ 확장 설치 완료"
fi

# ✅ ⚠️ 문제 있는 확장 강제 재설치
for ext in segment-anything tagcomplete; do
    echo "♻️ [$ext] 재설치 중 (버그 해결 목적)"
    rm -rf "$EXT_DIR/$ext"
    git clone "${EXTENSIONS[$ext]}" "$EXT_DIR/$ext" || {
        echo "❌ $ext 재설치 실패"
        exit 1
    }
done

# ✅ WebUI requirements.txt 설치
cd "$WEBUI_DIR"
if [ -f "requirements.txt" ]; then
    echo "📦 requirements.txt 설치 중..."
    pip install -r requirements.txt || echo "⚠️ requirements.txt 설치 실패"
else
    echo "❌ requirements.txt가 없음!"
fi

# ✅ gradio 강제 설치 + 검증
echo "📦 gradio 설치 중..."
pip install gradio==4.14.0 || echo "⚠️ gradio 설치 실패"
python -c "import gradio; print('✅ gradio 설치 확인:', gradio.__version__)" || { echo "❌ gradio import 실패"; exit 1; }

# ✅ 사용자 패키지 설치
if [ -f "$USER_REQUIREMENTS" ]; then
    echo "📥 사용자 패키지 설치 중 (--no-deps)"
    pip install --no-deps -r "$USER_REQUIREMENTS"
fi

# ✅ 패키지 상태 저장
pip freeze > /workspace/.current_installed.txt
if ! cmp -s /workspace/.current_installed.txt "$LAST_FREEZE"; then
    cp /workspace/.current_installed.txt "$USER_REQUIREMENTS"
    cp /workspace/.current_installed.txt "$LAST_FREEZE"
    echo "💾 requirements-user.txt 갱신됨"
fi

# ✅ PYTHONPATH 설정 (controlnet/scripts 제외)
PY_SCRIPTS_PATHS=""
for ext in "$EXT_DIR"/*; do
    extname=$(basename "$ext")
    if [ "$extname" != "controlnet" ] && [ -d "$ext/scripts" ]; then
        PY_SCRIPTS_PATHS="$PY_SCRIPTS_PATHS:$ext/scripts"
    fi
done
export PYTHONPATH="$PYTHONPATH$PY_SCRIPTS_PATHS"
echo "✅ PYTHONPATH 설정됨: $PY_SCRIPTS_PATHS"

# ✅ 확장 목록 출력
echo "📂 설치된 확장:"
ls -1 "$EXT_DIR"

# ✅ WebUI 실행
echo "🚀 WebUI 실행 시작"
python launch.py --xformers --listen --enable-insecure-extension-access
