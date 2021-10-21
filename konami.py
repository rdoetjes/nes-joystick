#!/usr/bin/env python3

import os

for root, dirs, files in os.walk("./"):
    for file in files:
        if file.endswith(".nes"):
            with open(os.path.join(root, file), 'rb') as f:
                s = f.read()
                f.close()
            if s.find(b'\x08\x08\x04\x04\x02\x01\x02\x01\x40\x80') != -1:
                print(os.path.join(root,file))
                










