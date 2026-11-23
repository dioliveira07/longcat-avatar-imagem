# Imagem pronta do LongCat-Video-Avatar 1.6 (só código + dependências; pesos baixam no boot, em paralelo).
# Mesmo conteúdo do pod_setup.sh, congelado. Sem segredo nenhum dentro: pode ser pública.
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
ENV DEBIAN_FRONTEND=noninteractive PIP_NO_CACHE_DIR=1 HF_HUB_ENABLE_HF_TRANSFER=1
RUN apt-get update -qq && apt-get install -y -qq ffmpeg libsndfile1 git curl openssh-server && rm -rf /var/lib/apt/lists/*
WORKDIR /root/w
RUN git clone -q --depth 1 --branch main https://github.com/meituan-longcat/LongCat-Video
RUN pip install -q "huggingface_hub[hf_transfer]" ninja psutil packaging \
    https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1+cu12torch2.6cxx11abiFALSE-cp311-cp311-linux_x86_64.whl \
 && pip install -q transformers==4.41.0 loguru==0.7.2 diffusers==0.35.1 einops==0.8.0 ftfy==6.2.0 av==12.0.0 \
    opencv-python-headless==4.9.0.80 imageio==2.37.0 imageio-ffmpeg==0.6.0 ffmpeg-python \
 && grep -vE 'libsndfile1|tritonserverclient' LongCat-Video/requirements_avatar.txt > /tmp/req.txt \
 && pip install -q -r /tmp/req.txt
COPY patch_audio_cfg.py /root/patch_audio_cfg.py
RUN python /root/patch_audio_cfg.py /root/w/LongCat-Video && python -c "import flash_attn,transformers,librosa,audio_separator"
