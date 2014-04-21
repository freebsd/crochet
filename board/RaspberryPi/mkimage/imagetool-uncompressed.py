#!/usr/bin/env python

import os
import re
import sys

# Template and parameters are stored in same directory
# as this Python file
PATH=os.path.dirname(__file__)

try:
   input_image = sys.argv[1]
   output_image = sys.argv[2]
except:
   input_image = ""

# Open input (which may be stdin)
if input_image == "":
  sys.stderr.write("usage : imagetool-uncompressed.py <input image> <output image>\n");
  sys.exit(0)
elif not input_image or input_image == '-':
   if sys.version_info.major == 3:
      infile = sys.stdin.buffer
   else:
      infile = sys.stdin
else:
   infile = open(input_image, "rb")

# Open output (which may be stdout)
if not output_image or output_image == '-':
   if sys.version_info.major == 3:
      outfile = sys.stdout.buffer
   else:
      outfile = sys.stdout
else:
   outfile = open(output_image, "wb")

# Read in template for first 32k   
f = open(os.path.join(PATH, "first32k.bin"), "rb")
mem = bytearray(f.read(32768))
f.close()

# Overlay boot parameters and args onto template
def load_to_mem(name, addr):
   f = open(os.path.join(PATH, name))

   for l in f.readlines():
      if l.startswith('0x'):
         value = int(l, 0)
         for i in range(4):
            mem[addr] = int((value >> i * 8) & 0xff)
            addr += 1

   f.close()
load_to_mem("boot-uncompressed.txt", 0x00000000)
load_to_mem("args-uncompressed.txt", 0x00000100)

# Write out header
outfile.write(mem)

# Copy input image after header
while True:
   piece = infile.read(4096)
   if not piece:
      break # end of file
   outfile.write(piece)

# Close files
infile.close()
outfile.close()
