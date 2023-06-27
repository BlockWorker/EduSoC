import png
import os
from joblib import Parallel, delayed

img = png.Reader(filename='img.png').read()

if img[0] != 640 or img[1] != 360:
    print('Image must be 640x360')
    exit(1)

rows = list(img[2])
mem = []

for r in rows:
    num_px = len(r) // 4
    for j in range(num_px // 4):
        memvals = []
        for k in range(4):
            offs = j * 16 + k * 4
            red = min(int(r[offs] / 255. * 8), 7)
            green = min(int(r[offs + 1] / 255. * 8), 7)
            blue = min(int(r[offs + 2] / 255. * 4), 3)
            memvals.append(f'{((red << 5) | (green << 2) | blue):02x}')
        memvals.reverse()
        mem.append(''.join(memvals))

memstr = '\n'.join(mem)

f = open('frame_buffer.mem', 'w')
f.write(memstr)
f.close()
