# Reforço SÓ de áudio no modo acelerado (distill) do LongCat 1.6: 2 passadas por passo (com e sem áudio).
# pred = sem_audio + LC_AUDIO_CFG * (com_audio - sem_audio). Sem a env (ou <=1) = comportamento original.
# Vale para at2v, ai2v (1º trecho) e avc (continuações).
import re,sys
p=sys.argv[1]+'/longcat_video/pipeline_longcat_video_avatar.py'; s=open(p).read()
if 'LC_AUDIO_CFG' in s: print('já aplicado'); sys.exit()
pat=re.compile(r'\n( +)noise_pred = self\.dit\(\n(.*?)\n\1\)\n', re.S)
def rep(m):
    ind,body=m.group(1),m.group(2)
    if 'audio_embs=audio_cond_embs' not in body: return m.group(0)
    body0=re.sub(r'audio_embs=audio_cond_embs\s*,', 'audio_embs=torch.zeros_like(audio_cond_embs),', body)
    return (m.group(0)+
      f"{ind}_acfg=float(__import__('os').environ.get('LC_AUDIO_CFG','0') or 0)\n"
      f"{ind}if _acfg>1.0 and not self.do_classifier_free_guidance:\n"
      f"{ind}    _sem_audio = self.dit(\n" + '\n'.join('    '+l for l in body0.split('\n')) + f"\n{ind}    )\n"
      f"{ind}    noise_pred = _sem_audio + _acfg * (noise_pred - _sem_audio)\n")
s2,n=pat.subn(rep,s)
k=s2.count('_sem_audio = self.dit(')
assert k==3, f'esperava 3 lugares (at2v/ai2v/avc), achei {k}'
open(p,'w').write(s2); print('patch audio_cfg ok em',k,'lugares')
