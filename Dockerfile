FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_CACHE_DIR=/workspace/.cache/pip

# 필수 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    git wget curl ffmpeg libgl1 \
    build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev \
    liblzma-dev software-properties-common \
    locales sudo tzdata xterm nano \
    nodejs npm && \
    apt-get clean

# 정확한 Python 3.10.6 설치
WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz && \
    tar xzf Python-3.10.6.tgz && cd Python-3.10.6 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && make altinstall && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/local/bin/pip3.10 /usr/bin/pip && \
    ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip && \
    cd / && rm -rf /tmp/*

# 최신 Node.js 18 설치
RUN apt-get remove -y nodejs npm && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# 작업 디렉토리 생성
WORKDIR /workspace
RUN mkdir -p /workspace && chmod -R 777 /workspace && chown -R root:root /workspace

# AUTOMATIC1111 WebUI 설치
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /workspace/stable-diffusion-webui

# 모델 디렉토리 준비
RUN mkdir -p /workspace/stable-diffusion-webui/models/Stable-diffusion

# ADetailer 확장 설치
RUN git clone https://github.com/Bing-su/adetailer.git /workspace/stable-diffusion-webui/extensions/adetailer

# [추가] SDXL 필수 리포지토리
RUN git clone https://github.com/Stability-AI/generative-models.git /workspace/stable-diffusion-webui/repositories/generative-models


# Python 패키지 설치 (torch 버전 고정 포함 + ADetailer 추가)
WORKDIR /workspace/stable-diffusion-webui
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip uninstall -y torch torchvision torchaudio xformers pydantic && \
    pip install torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121 && \
    pip install xformers==0.0.22.post7 --extra-index-url https://download.pytorch.org/whl/cu121 && \
    pip install pydantic==1.10.13 rich && \
    pip install ultralytics opencv-python-headless numpy && \
    pip install -e /workspace/stable-diffusion-webui/repositories/generative-models  # [추가]

# 2. FastAPI UI 에러 방지를 위한 정적 리포 추가
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets \
    /workspace/stable-diffusion-webui/repositories/stable-diffusion-webui-assets


# JupyterLab 설치 및 설정
RUN pip install --force-reinstall jupyterlab==3.6.6 jupyter-server==1.23.6 && \
    mkdir -p /root/.jupyter && \
    echo "c.NotebookApp.allow_origin = '*'\n\
c.NotebookApp.ip = '0.0.0.0'\n\
c.NotebookApp.open_browser = False\n\
c.NotebookApp.token = ''\n\
c.NotebookApp.password = ''\n\
c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}" \
> /root/.jupyter/jupyter_notebook_config.py

# 포트 오픈
EXPOSE 7860
EXPOSE 8888

# 실행 커맨드: WebUI + JupyterLab 병렬 실행
CMD bash -c "\
jupyter lab --ip=0.0.0.0 --port=8888 --allow-root \
--ServerApp.token='' --ServerApp.password='' & \
python /workspace/stable-diffusion-webui/launch.py \
--xformers --listen --port 7860 --enable-insecure-extension-access & \
wait"
