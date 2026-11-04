#!/usr/bin/env bash
# Regenerates the synthetic demo clips used by example/slides.qmd (needs ffmpeg).
# Replace them with your own footage; nothing else depends on these files.
set -euo pipefail
cd "$(dirname "$0")"
x264="-c:v libx264 -preset fast -pix_fmt yuv420p -an"

# (a) embedded clip: an orange Lissajous figure on white
ffmpeg -y -loglevel error -f lavfi \
  -i "aevalsrc=0.85*sin(2*PI*0.5*t+0.15*t*t)|0.85*sin(2*PI*0.33*t):s=8000:d=8" \
  -filter_complex "[0:a]avectorscope=s=320x180:r=30:mode=lissajous_xy:draw=line:scale=lin:rc=255:gc=255:bc=255:ac=255:rf=1:gf=1:bf=1:af=1,format=rgb24,lutrgb=r='255-val*61/255':g='255-val*170/255':b='255-val*247/255',scale=960:540:flags=bicubic[v]" \
  -map "[v]" $x264 -crf 26 lissajous.mp4

# (b) full-slide background: slow dark ink/orange gradient
ffmpeg -y -loglevel error -f lavfi \
  -i "gradients=size=1280x720:rate=24:c0=0x1a1a1a:c1=0x5a2604:c2=0x262626:c3=0x8a3c06:nb_colors=4:speed=0.01" \
  -t 10 $x264 -crf 32 background.mp4

# (c) side by side: Game of Life and rule-110 automaton in Princeton colours
ffmpeg -y -loglevel error -f lavfi \
  -i "life=size=160x90:rate=12:mold=10:ratio=0.1:death_color=#262626:life_color=#ED6D0B:mold_color=#C25508:seed=7" \
  -t 8 -vf "scale=640:360:flags=neighbor" $x264 -crf 28 life-a.mp4
ffmpeg -y -loglevel error -f lavfi \
  -i "cellauto=size=320x180:rate=12:rule=110:random_fill_ratio=0.5:seed=3:scroll=1" \
  -t 8 -vf "lutrgb=r='if(val,255,194)':g='if(val,255,85)':b='if(val,255,8)',scale=640:360:flags=neighbor" \
  $x264 -crf 28 life-b.mp4
