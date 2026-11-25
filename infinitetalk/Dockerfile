# syntax=docker/dockerfile:1
# Imagem pronta do InfiniteTalk (MeiGen-AI) — imagem+áudio → vídeo, com controle de audio CFG.
# Só código + dependências (receita do pod_abc.sh 24/11, congelada). Pesos baixam no boot (baixar_pesos.py, hf_transfer).
# Sem segredo nenhum dentro: pode ser pública.
FROM pytorch/pytorch:2.4.1-cuda12.1-cudnn9-devel
ENV DEBIAN_FRONTEND=noninteractive PIP_NO_CACHE_DIR=1 HF_HUB_ENABLE_HF_TRANSFER=1 PYTHONUNBUFFERED=1
RUN apt-get update -qq && apt-get install -y -qq ffmpeg libsndfile1 libgl1 git curl openssh-server && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN printf 'torch==2.4.1\ntorchvision==0.19.1\ntorchaudio==2.4.1\nxformers==0.0.28.post1\nnumpy<2\n' > /opt/it_c.txt \
 && pip install -q xformers==0.0.28.post1 --index-url https://download.pytorch.org/whl/cu121 -c /opt/it_c.txt \
 && PYV=$(python -c 'import sys;print(f"cp{sys.version_info[0]}{sys.version_info[1]}")') \
 && pip install -q ninja psutil packaging wheel "huggingface_hub[hf_transfer]" hf_transfer -c /opt/it_c.txt \
    "https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1+cu12torch2.4cxx11abiFALSE-${PYV}-${PYV}-linux_x86_64.whl"
RUN git clone -q --depth 1 https://github.com/MeiGen-AI/InfiniteTalk /opt/InfiniteTalk \
 && grep -vE 'gradio|dashscope' /opt/InfiniteTalk/requirements.txt > /opt/it_req.txt \
 && pip install -q -r /opt/it_req.txt librosa soundfile pyloudnorm -c /opt/it_c.txt \
 && python - <<'P'
p='/opt/InfiniteTalk/generate_infinitetalk.py'; s=open(p).read()
s=s.replace('from kokoro import KPipeline','try:\n    from kokoro import KPipeline\nexcept Exception:\n    KPipeline = None')
open(p,'w').write(s)
P
COPY baixar_pesos.py gerar.sh /opt/it/
RUN chmod +x /opt/it/gerar.sh && cd /opt/InfiniteTalk \
 && python -c "import torch,xformers,flash_attn,transformers,librosa,hf_transfer,decord,diffusers;print('torch',torch.__version__,'xformers',xformers.__version__,'flash',flash_attn.__version__)"
