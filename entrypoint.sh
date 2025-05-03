#!/bin/bash
set -e

echo "[0] Python 3.10.6 직접 설치 중..."
cd /tmp
wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz
tar xzf Python-3.10.6.tgz
cd Python-3.10.6
./configure --enable-optimizations
make -j$(nproc)
make altinstall
ln -sf /usr/local/bin/python3.10 /usr/bin/python
ln -sf /usr/local/bin/pip3.10 /usr/bin/pip
rm -rf /tmp/*

echo "[1] 무거운 패키지 설치 중 (RunPod GPU 환경에 최적)"
pip install --no-cache-dir torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir xformers==0.0.22.post7 --extra-index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir pydantic==1.10.13 rich opencv-python-headless numpy ultralytics

echo "[2] generative-models 설치 중"
pip install --no-cache-dir -e /workspace/stable-diffusion-webui/repositories/generative-models

echo "[3] JupyterLab 설치 및 실행"
pip install --no-cache-dir jupyterlab==3.6.6 jupyter-server==1.23.6
mkdir -p /root/.jupyter
echo \"c.NotebookApp.allow_origin = '*'\"
echo \"c.NotebookApp.ip = '0.0.0.0'\"
echo \"c.NotebookApp.open_browser = False\"
echo \"c.NotebookApp.token = ''\"
echo \"c.NotebookApp.password = ''\"
echo \"c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}\" > /root/.jupyter/jupyter_notebook_config.py

echo \"[4] WebUI 및 Jupyter 병렬 실행\"
jupyter lab --ip=0.0.0.0 --port=8888 --allow-root & \
python /workspace/stable-diffusion-webui/launch.py --xformers --listen --port 7860 --enable-insecure-extension-access & \
wait
