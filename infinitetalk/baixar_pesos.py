# Baixa os pesos do InfiniteTalk em /root/w (hf_transfer, em paralelo). Marca /root/w/PESOS_OK no fim.
import os, time, sys
from concurrent.futures import ThreadPoolExecutor
os.environ.setdefault("HF_HUB_ENABLE_HF_TRANSFER", "1")
from huggingface_hub import snapshot_download as s, hf_hub_download as d
W = os.environ.get("IT_PESOS", "/root/w"); os.makedirs(W, exist_ok=True)
t0 = time.time()
def wan():  s('Wan-AI/Wan2.1-I2V-14B-480P', local_dir=f'{W}/Wan2.1-I2V-14B-480P', max_workers=16)
def w2v():
    s('TencentGameMate/chinese-wav2vec2-base', local_dir=f'{W}/chinese-wav2vec2-base')
    d('TencentGameMate/chinese-wav2vec2-base', 'model.safetensors', revision='refs/pr/1', local_dir=f'{W}/chinese-wav2vec2-base')
def it():   s('MeiGen-AI/InfiniteTalk', local_dir=f'{W}/InfiniteTalk', allow_patterns=['single/*'])
def lora(): d('Kijai/WanVideo_comfy', 'Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors', local_dir=W)
with ThreadPoolExecutor(4) as ex:
    fs = [ex.submit(f) for f in (wan, w2v, it, lora)]
    for f in fs: f.result()
open(f'{W}/PESOS_OK', 'w').write(f'{time.time()-t0:.0f}\n')
print(f'PESOS_OK {time.time()-t0:.0f}s', flush=True)
