#!/usr/bin/env python

import os
import re
import sys

try:
   input_image = sys.argv[1]
   output_image = sys.argv[2]
except:
   input_image = ""

if input_image == "":
  print("usage : imagetool-uncompressed.py <input image> <output image>");
  sys.exit(0)
   
re_line = re.compile(r"0x(?P<value>[0-9a-f]{8})")

mem = [0 for i in range(32768)]

def load_to_mem(name, addr):
   f = open(name)

   for l in f.readlines():
      m = re_line.match(l)

      if m:
         value = int(m.group("value"), 16)

         for i in range(4):
            mem[addr] = int(value >> i * 8 & 0xff)
            addr += 1

   f.close()

load_to_mem("boot-uncompressed.txt", 0x00000000)
load_to_mem("args-uncompressed.txt", 0x00000100)

f = open("first32k.bin", "wb")

for m in mem:
   f.write(chr(m))

f.close()

os.system("cat first32k.bin " + input_image + " > " + output_image)
