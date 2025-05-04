#!/bin/bash

# ====================================
# 🧳 Hugging Face API 키 (필요 입력)
# ====================================
HUGGINGFACE_TOKEN="Huggingface_Token_key"

# ====================================
# 🛠️ 사용자 설정값
# ====================================
MAX_PARALLEL=10

# ====================================
# 📂 파일 설정
# ====================================
INPUT_FILE="aria2_downloads.txt"
LOG_FILE="aria2_log.txt"
RESULT_FILE="aria2_result.txt"

# ====================================
# ⏱️ 타이머 시작
# ====================================
start_time=$(date +%s)

# ====================================
# 📦 Aria2 설치 확인
# ====================================
if ! command -v aria2c &> /dev/null; then
    echo "📦 aria2c가 설치되지 않았습니다. 설치를 시작합니다..."
    sudo apt update && sudo apt install -y aria2
    if [ $? -ne 0 ]; then
        echo "❌ aria2 설치 실패. 수동 설치 필요."
        exit 1
    fi
else
    echo "✅ aria2c 설치 확인 완료."
fi

# ====================================
# 🔐 사전 토큰 유효성 검사
# ====================================
TEST_URL="https://huggingface.co/black-forest-labs/FLUX.1-Fill-dev/resolve/main/flux1-fill-dev.safetensors"
echo "🔍 Hugging Face API 키 유효성 검사 중..."

test_response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $HUGGINGFACE_TOKEN" "$TEST_URL")

if [[ "$test_response" == "403" || "$test_response" == "401" ]]; then
    echo -e "\n\033[0;31m🚫 오류: Hugging Face API 키가 유효하지 않습니다! (에러코드: $test_response)\033[0m"
    echo "# 🚫 잘못된 Hugging Face API 키 검지됨 (에러 $test_response)" | tee -a "$RESULT_FILE"
    echo "# 5초 대기 후, 인증 없이 받을 수 있는 파일들부터 다운로드를 시작합니다..." | tee -a "$RESULT_FILE"
    sleep 5
else
    echo "✅ Hugging Face API 키 인증 성공 ($test_response)"
fi

# ====================================
# 📌 다운로드 리스트
# ====================================
downloads=(
  # ControlNet 모델
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11e_sd15_ip2p_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11e_sd15_ip2p_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11e_sd15_shuffle_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11e_sd15_shuffle_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11f1e_sd15_tile_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11f1e_sd15_tile_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11f1p_sd15_depth_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11f1p_sd15_depth_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_canny_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_canny_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_inpaint_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_inpaint_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_lineart_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_lineart_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_mlsd_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_mlsd_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_normalbae_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_normalbae_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_openpose_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_openpose_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_scribble_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_scribble_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_seg_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_seg_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_softedge_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15_softedge_fp16.safetensors"
  "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15s2_lineart_anime_fp16.safetensors|/workspace/stable-diffusion-webui/extensions/controlnet/models/control_v11p_sd15s2_lineart_anime_fp16.safetensors"

  # VAE 모델
  "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors|/workspace/stable-diffusion-webui/models/VAE/vae-ft-mse-840000-ema-pruned.safetensors"
  "https://huggingface.co/hakurei/waifu-diffusion-v1-4/resolve/main/vae/kl-f8-anime2.ckpt|/workspace/stable-diffusion-webui/models/VAE/kl-f8-anime2.ckpt"
  "https://huggingface.co/digiplay/VAE/resolve/main/color101VAE_v1.safetensors|/workspace/stable-diffusion-webui/models/VAE/color101VAE_v1.safetensors"

  # Embedding
  "https://huggingface.co/datasets/gsdf/EasyNegative/resolve/main/EasyNegative.safetensors|/workspace/stable-diffusion-webui/embeddings/EasyNegative.safetensors"
)

# ====================================
# 🧹 초기화
# ====================================
rm -f "$INPUT_FILE" "$LOG_FILE" "$RESULT_FILE"

# ====================================
# 📋 리스트 생성
# ====================================
for item in "${downloads[@]}"; do
  IFS="|" read -r url path <<< "$item"
  if [ -f "$path" ]; then
    echo "[완료] 이미 존재: $path" | tee -a "$RESULT_FILE"
  else
    mkdir -p "$(dirname "$path")"
    echo "$url" >> "$INPUT_FILE"
    echo "  dir=$(dirname "$path")" >> "$INPUT_FILE"
    echo "  out=$(basename "$path")" >> "$INPUT_FILE"
  fi
done

# ====================================
# 🚀 다운로드 시작
# ====================================
if [ -s "$INPUT_FILE" ]; then
  echo -e "\n🚀 다운로드 시작...\n"
  aria2c -x 8 -j "$MAX_PARALLEL" -i "$INPUT_FILE" \
         --console-log-level=notice --summary-interval=1 \
         --header="Authorization: Bearer $HUGGINGFACE_TOKEN" \
         | tee -a "$LOG_FILE"
else
  echo "📂 다운로드할 항목이 없습니다."
fi

# ====================================
# ✅ 결과 반영
# ====================================
total=${#downloads[@]}
success=0
failures=()

for item in "${downloads[@]}"; do
  IFS="|" read -r url path <<< "$item"
  if [ -f "$path" ]; then
    echo "[완료] $path" | tee -a "$RESULT_FILE"
    ((success++))
  else
    echo "[실패] $path" | tee -a "$RESULT_FILE"
    failures+=("$path")
  fi
done

# ====================================
# ⏱️ 소요 시간
# ====================================
end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

echo -e "\n🕒 총 소요 시간: ${minutes}분 ${seconds}초\n" | tee -a "$RESULT_FILE"

# ====================================
# 📊 참가 요약
# ====================================
if [ "$success" -eq "$total" ]; then
  echo "✅ $success/$total 모든 파일 정상!" | tee -a "$RESULT_FILE"
else
  echo "❌ $success/$total 건강, ${#failures[@]} 실패" | tee -a "$RESULT_FILE"
  echo "🔹 실패 파일 목록:" | tee -a "$RESULT_FILE"
  for fail in "${failures[@]}"; do
    echo " - $fail" | tee -a "$RESULT_FILE"
  done
fi

# ====================================
# ❌ 다중 실패 파일 처리
# ====================================
echo -e "\n🔍 다중 실패(또는 중단) 파일 검사..."
broken_files=()

for item in "${downloads[@]}"; do
  IFS="|" read -r url path <<< "$item"
  if [[ -f "$path" && ! -s "$path" ]] || [[ -f "$path.aria2" ]]; then
    broken_files+=("$path")
  fi
done

if [ "${#broken_files[@]}" -gt 0 ]; then
  echo -e "\n🚨 ${#broken_files[@]}개의 중단/잘못된 파일 검사 완료."
  for bf in "${broken_files[@]}"; do
    echo " - $bf"
  done

  echo -e "\n❓ 자동으로 삭제하고 다시 다운로드 하시겠습니까? (Y/N): \c"
  read -r confirm_retry

  if [[ "$confirm_retry" == "Y" || "$confirm_retry" == "y" ]]; then
    echo "🗑️ 삭제 중..."
    for bf in "${broken_files[@]}"; do
      rm -f "$bf" "$bf.aria2"
      echo "삭제됨: $bf"
    done
    echo "♻️ 다시 시작합니다..."
    bash "$0"
    exit 0
  else
    echo "❌ 재시도 없이 종료합니다."
    exit 0
  fi
else
  echo "✅ 모든 파일이 정상적으로 다운되었습니다."
   # ====================================
  # 🎓 AI 교육 & 커뮤니티 안내 (Community & EDU)
  # ====================================
  echo -e "\n====🎓 AI 교육 & 커뮤니티 안내====\n"
  echo -e "1. Youtube : https://www.youtube.com/@A01demort"
  echo "2. 교육 문의 : https://a01demort.com"
  echo "3. Udemy 강의 : https://bit.ly/comfyclass"
  echo "4. Stable AI KOREA : https://cafe.naver.com/sdfkorea"
  echo "5. 카카오톡 오픈채팅방 : https://open.kakao.com/o/gxvpv2Mf"
  echo "6. CIVITAI : https://civitai.com/user/a01demort"
  echo -e "\n==================================="
fi
