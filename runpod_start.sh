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

echo "🧹 [INIT] 캐시 및 환경 초기화 시작..."

# 🔄 캐시/컴파일된 파이썬 파일 삭제 (restart 꼬임 방지)
find "$WEBUI_DIR" -type d -name "__pycache__" -exec rm -rf {} +
find "$WEBUI_DIR" -name "*.pyc" -delete
rm -rf ~/.nv 2>/dev/null || true

# 🔄 PYTHONPATH 재설정 (확장 기능 import 문제 해결)
export PYTHONPATH=$PYTHONPATH:\
$EXT_DIR/sd-webui-controlnet/scripts:\
$EXT_DIR/sd-webui-segment-anything/scripts:\
$EXT_DIR/a1111-sd-webui-tagcomplete/scripts

echo "✅ 캐시 제거 및 PYTHONPATH 설정 완료"

# 📦 확장 기능 자동 설치
if [ ! -d "$EXT_DIR/adetailer" ]; then
    echo "📦 확장 기능 및 리포지토리 설치 시작..."

    mkdir -p "$WEBUI_DIR/models/Stable-diffusion"

    git clone https://github.com/Stability-AI/generative-models.git "$REPO_DIR/generative-models"
    pip install -e "$REPO_DIR/generative-models"

    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets "$ASSET_DIR"

    for name in "${!EXTENSIONS[@]}"; do
        dst="$EXT_DIR/$name"
        repo="${EXTENSIONS[$name]}"
        if [ ! -d "$dst" ]; then
            echo "🔗 [$name] 설치 중..."
            git clone "$repo" "$dst"
        else
            echo "✅ [$name] 이미 설치됨"
        fi
    done

    cd "$WEBUI_DIR"
    pip install -r requirements.txt
    echo "✅ 확장 및 리포지토리 설치 완료"
fi

# 📄 사용자 의존성 복구
if [ -f "$USER_REQUIREMENTS" ]; then
    echo "📥 사용자 패키지 설치 중 (--no-deps)"
    pip install --no-deps -r "$USER_REQUIREMENTS"
fi

# 🔄 pip 상태 추적
pip freeze > /workspace/.current_installed.txt
if ! cmp -s /workspace/.current_installed.txt "$LAST_FREEZE"; then
    cp /workspace/.current_installed.txt "$USER_REQUIREMENTS"
    cp /workspace/.current_installed.txt "$LAST_FREEZE"
    echo "💾 requirements-user.txt 갱신됨"
fi

# 📂 설치된 확장 목록 출력 (확인용)
echo "📂 현재 설치된 확장 목록:"
ls -1 "$EXT_DIR"

# 🚀 WebUI 실행
cd "$WEBUI_DIR"
echo "🚀 WebUI 실행 시작"
python launch.py --xformers --listen --enable-insecure-extension-access
