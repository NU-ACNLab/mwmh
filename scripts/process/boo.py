import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', default='/projects/b1108/data/MWMH/fmriprep/')
parser.add_argument('-o', default='/projects/b1108/data/MWMH/amygconn/')
parser.add_argument('-s')
parser.add_argument('-ss')
args = parser.parse_args()

inDir = args.i
outDir = args.o
sub = args.s
ses = args.ss

print(inDir)
print(outDir)
print(sub)
print(ses)
