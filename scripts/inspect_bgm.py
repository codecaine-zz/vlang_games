import os
import re

dirs = sorted([d for d in os.listdir('.') if os.path.isdir(d) and not d.startswith('.') and d not in ('assets', 'engine', 'scripts', 'air_hockey') and os.path.exists(os.path.join(d, 'main.v'))])

music_dir = 'assets/music'
sounds_dir = 'assets/sounds'

existing_music = set(os.listdir(music_dir))
existing_sounds = set(os.listdir(sounds_dir))

missing_bgm_files = []
has_bgm = []
no_bgm_pattern = []

for d in dirs:
    sv = os.path.join(d, 'sound.v')
    content = open(sv).read()
    clips = re.findall(r"load_clip\(\s*'([^']+)'\s*,\s*'([^']+)'\s*\)", content)
    bgm_clips = [(k, v) for k, v in clips if 'bgm' in k or 'bgm' in v or 'theme' in v or 'chill' in v or 'fever' in v or 'shop' in v]
    if not bgm_clips:
        no_bgm_pattern.append(d)
        continue
    
    found = False
    for k, v in bgm_clips:
        if v in existing_music or v in existing_sounds:
            found = True
            break
    if found:
        has_bgm.append((d, bgm_clips))
    else:
        missing_bgm_files.append((d, bgm_clips))

print(f"Games with working BGM file ({len(has_bgm)})")
print(f"Games with missing BGM file ({len(missing_bgm_files)}):")
for d, clips in missing_bgm_files:
    print(f"  {d}: {clips}")
print(f"Games with no BGM pattern in load_clip ({len(no_bgm_pattern)}):")
for d in no_bgm_pattern:
    print(f"  {d}")
