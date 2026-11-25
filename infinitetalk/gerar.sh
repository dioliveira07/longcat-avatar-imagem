#!/bin/bash
# Roda DENTRO da máquina. gerar.sh IMAGEM AUDIO SAIDA.mp4 [ACFG=4] [TAMANHO=infinitetalk-480] [TRECHO_S=60] [PROMPT_B64]
# Corta o áudio em trechos de ~TRECHO_S (no silêncio mais próximo, em fronteira de quadro 25 fps), gera cada trecho com a
# mesma imagem, ajusta cada vídeo ao tamanho exato do trecho, junta e põe o áudio original. Imprime GERAR_OK no fim.
set -euo pipefail
IMG=$1; AUD=$2; OUT=$3; ACFG=${4:-4}; SIZE=${5:-infinitetalk-480}; TRECHO=${6:-60}
PROMPT=$( [ -n "${7:-}" ] && echo "$7" | base64 -d || echo "A person looks straight into the camera and talks naturally, subtle natural head movement, natural blinking, photorealistic")
W=${IT_PESOS:-/root/w}; T=/root/it_job; rm -rf $T; mkdir -p $T
L(){ echo "$(date +%H:%M:%S) $*"; }
for _ in $(seq 1 240); do [ -f $W/PESOS_OK ] && break; sleep 15; done
[ -f $W/PESOS_OK ] || { L "ERRO pesos não baixaram"; exit 2; }
L "pesos ok ($(cat $W/PESOS_OK)s)"
ffmpeg -v error -y -i "$AUD" -ar 16000 -ac 1 $T/full.wav
python - "$T" "$TRECHO" <<'P'
import subprocess, sys, re, json
T, alvo = sys.argv[1], float(sys.argv[2])
dur = float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0',f'{T}/full.wav']).decode())
log = subprocess.run(['ffmpeg','-i',f'{T}/full.wav','-af','silencedetect=n=-35dB:d=0.25','-f','null','-'],capture_output=True,text=True).stderr
sil = [(float(a)+float(b))/2 for a,b in zip(re.findall(r'silence_start: ([\d.]+)',log), re.findall(r'silence_end: ([\d.]+)',log))]
cortes, ini = [], 0.0
while dur - ini > alvo * 1.15:
    cand = [s for s in sil if ini + alvo*0.7 <= s <= ini + alvo]
    c = max(cand) if cand else ini + alvo
    c = round(c * 25) / 25            # fronteira de quadro
    cortes.append(c); ini = c
pts = [0.0] + cortes + [dur]
json.dump([[pts[i], pts[i+1]] for i in range(len(pts)-1)], open(f'{T}/trechos.json','w'))
print('trechos', [[round(a,2),round(b,2)] for a,b in zip(pts,pts[1:])])
P
N=$(python -c "import json;print(len(json.load(open('$T/trechos.json'))))")
cd /opt/InfiniteTalk; : > $T/lista.txt
for i in $(seq 0 $((N-1))); do
  read -r A B <<< "$(python -c "import json;a,b=json.load(open('$T/trechos.json'))[$i];print(a,b)")"
  D=$(python -c "print($B-$A)"); NF=$(python -c "import math;print(round($B*25)-round($A*25))")
  ffmpeg -v error -y -i $T/full.wav -ss "$A" -t "$D" -c:a pcm_s16le $T/a$i.wav
  PROMPT="$PROMPT" python -c "import json,os;json.dump({'prompt':os.environ['PROMPT'],'cond_video':'$IMG','cond_audio':{'person1':'$T/a$i.wav'}},open('$T/in$i.json','w'))"
  L "trecho $((i+1))/$N: ${D}s ($NF quadros) acfg=$ACFG $SIZE"
  python generate_infinitetalk.py --ckpt_dir $W/Wan2.1-I2V-14B-480P --wav2vec_dir $W/chinese-wav2vec2-base \
    --infinitetalk_dir $W/InfiniteTalk/single/infinitetalk.safetensors \
    --lora_dir $W/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors --lora_scale 1.0 \
    --input_json $T/in$i.json --size "$SIZE" --sample_text_guide_scale 1.0 --sample_audio_guide_scale "$ACFG" \
    --sample_steps 8 --sample_shift 2 --mode streaming --motion_frame 9 --max_frame_num $((NF+200)) \
    --save_file $T/v$i > $T/gen$i.log 2>&1 || { L "ERRO geração trecho $i"; tail -20 $T/gen$i.log; exit 3; }
  # vídeo do trecho com o tamanho exato do áudio do trecho (sem som; o áudio original entra no fim)
  VI=$(ls -t $T/v$i*.mp4 | head -1)
  ffmpeg -v error -y -i "$VI" -an -vf "fps=25,tpad=stop_mode=clone:stop_duration=3" -frames:v $NF -c:v libx264 -crf 14 -preset medium -pix_fmt yuv420p $T/c$i.mp4
  echo "file '$T/c$i.mp4'" >> $T/lista.txt
  L "trecho $((i+1)) ok"
done
ffmpeg -v error -y -f concat -safe 0 -i $T/lista.txt -c copy $T/video.mp4
ffmpeg -v error -y -i $T/video.mp4 -i "$AUD" -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "$OUT"
L "GERAR_OK $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")s"
