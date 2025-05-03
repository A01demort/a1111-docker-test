# Dockerfile
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# 필수 시스템 패키지 설치 (Jupyter, Node.js 포함, Python 빌드는 RunPod에서)
RUN apt-get update && apt-get install -y \
    git wget curl unzip nano ffmpeg libgl1 \
    build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev \
    locales sudo tzdata xterm \
    nodejs npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.js 최신 18버전으로 교체
RUN apt-get remove -y nodejs npm && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# 작업 디렉토리 설정
WORKDIR /workspace
RUN mkdir -p /workspace && chmod -R 777 /workspace && chown -R root:root /workspace

# stable-diffusion-webui clone
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git

# ADetailer 확장 및 generative-models clone
RUN git clone https://github.com/Bing-su/adetailer.git /workspace/stable-diffusion-webui/extensions/adetailer && \
    git clone https://github.com/Stability-AI/generative-models.git /workspace/stable-diffusion-webui/repositories/generative-models && \
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets \
        /workspace/stable-diffusion-webui/repositories/stable-diffusion-webui-assets

# entrypoint 복사
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 포트 오픈
EXPOSE 7860
EXPOSE 8888

CMD ["/entrypoint.sh"]

# entrypoint.sh (같은 디렉토리에 따로 저장)
# ===========================
#
# #!/bin/bash
# set -e
#
# echo "[0] Python 3.10.6 직접 설치 중..."
# cd /tmp
# wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz
# tar xzf Python-3.10.6.tgz
# cd Python-3.10.6
# ./configure --enable-optimizations
# make -j$(nproc)
# make altinstall
# ln -sf /usr/local/bin/python3.10 /usr/bin/python
# ln -sf /usr/local/bin/pip3.10 /usr/bin/pip
# rm -rf /tmp/*
#
# echo "[1] 무거운 패키지 설치 중 (RunPod GPU 환경에 최적)"
# pip install --no-cache-dir torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121
# pip install --no-cache-dir xformers==0.0.22.post7 --extra-index-url https://download.pytorch.org/whl/cu121
# pip install --no-cache-dir pydantic==1.10.13 rich opencv-python-headless numpy ultralytics
#
# echo "[2] generative-models 설치 중"
# pip install --no-cache-dir -e /workspace/stable-diffusion-webui/repositories/generative-models
#
# echo "[3] JupyterLab 설치 및 실행"
# pip install --no-cache-dir jupyterlab==3.6.6 jupyter-server==1.23.6
# mkdir -p /root/.jupyter
# echo "c.NotebookApp.allow_origin = '*'\nc.NotebookApp.ip = '0.0.0.0'\nc.NotebookApp.open_browser = False\nc.NotebookApp.token = ''\nc.NotebookApp.password = ''\nc.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}" > /root/.jupyter/jupyter_notebook_config.py
#
# echo "[4] WebUI 및 Jupyter 병렬 실행"
# jupyter lab --ip=0.0.0.0 --port=8888 --allow-root & \
# python /workspace/stable-diffusion-webui/launch.py --xformers --listen --port 7860 --enable-insecure-extension-access & \
# wait
