#!/bin/bash

# ====================================
# 🔐 Civitai API 키 (비워도 됨)
# ====================================
CIVITAI_TOKEN=""

# ====================================
# 📂 다운로드 리스트 (URL|파일명)
# ====================================
models=(
  "https://civitai.com/api/download/models/501240?type=Model&format=SafeTensor&size=pruned&fp=fp16|Realistic_Vision_V6.0_B1.safetensors"
  "https://civitai.com/api/download/models/1409849?type=Model&format=SafeTensor&size=pruned&fp=fp16|RealCartoon3D.safetensors"
  "https://civitai.com/api/download/models/11745?type=Model&format=SafeTensor&size=full&fp=fp16|Chilloutmix-Ni-pruned-fp32-fix.safetensors"
  "https://civitai.com/api/download/models/176425?type=Model&format=SafeTensor&size=pruned&fp=fp16|majicMIX_realistic_v7.safetensors"
  "https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16|DreamShaper_v8.safetensors"
  "https://civitai.com/api/download/models/425083?type=Model&format=SafeTensor&size=full&fp=fp16|ReV_Animated_V2_rebirth.safetensors"
  "https://civitai.com/api/download/models/105924?type=Model&format=SafeTensor&size=pruned&fp=fp16|CetusMix_WhaleFall2.safetensors"
  "https://civitai.com/api/download/models/17233?type=Model&format=SafeTensor&size=full&fp=fp16|AbyssOrangeMix3.safetensors"
  "https://civitai.com/api/download/models/76907?type=Model&format=SafeTensor&size=pruned&fp=fp16|GhostMix_v2.0-BakedVAE.safetensors"
  "https://civitai.com/api/download/models/1596786?type=Model&format=SafeTensor&size=pruned&fp=fp16|JANKU_Illustrious_XL_V3.safetensors"
  "https://civitai.com/api/download/models/1720768?type=Model&format=SafeTensor&size=pruned&fp=fp16|yberRealistic_XL_V5.6.safetensors"
  "https://civitai.com/api/download/models/403131?type=Model&format=SafeTensor&size=full&fp=fp16|Animagine_XL_V3.1.safetensors"
)

# ====================================
# 🕒 다운로드 시작
# ====================================
echo "🚀 Civitai 모델 순차 다운로드 시작..."

for item in "${models[@]}"; do
  IFS="|" read -r url filename <<< "$item"

  if [[ -f "$filename" ]]; then
    echo "✅ 이미 존재: $filename"
    continue
  fi

  echo "📥 다운로드 중: $filename"
  real_url=$(curl -s -L -w '%{url_effective}' -o /dev/null "$url")

  if [[ -z "$real_url" || "$real_url" == "$url" ]]; then
    echo "❌ 리다이렉션 실패: $url"
    continue
  fi

  if [[ -n "$CIVITAI_TOKEN" ]]; then
    curl -L -# -H "Authorization: Bearer $CIVITAI_TOKEN" -o "$filename" "$real_url"
  else
    curl -L -# -o "$filename" "$real_url"
  fi

  if [[ $? -ne 0 || ! -s "$filename" ]]; then
    echo "❌ 다운로드 실패: $filename"
    rm -f "$filename"
  else
    echo "✅ 완료: $filename"
  fi

  echo
done

# ====================================
# 🎓 AI 교육 & 커뮤니티 안내
# ====================================
echo -e "\n====🎓 AI 교육 & 커뮤니티 안내====\n"
echo "1. Youtube : https://www.youtube.com/@A01demort"
echo "2. 교육 문의 : https://a01demort.com"
echo "3. Udemy 강의 : https://bit.ly/comfyclass"
echo "4. Stable AI KOREA : https://cafe.naver.com/sdfkorea"
echo "5. 카카오톡 오픈채팅방 : https://open.kakao.com/o/gxvpv2Mf"
echo "6. CIVITAI : https://civitai.com/user/a01demort"
echo -e "\n==================================="
