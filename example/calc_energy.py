#A.S. Program to call tool_follow and output all the planet/particle data and put it into follow/
#Symba only uses massless particles, and so there is no particle-particle interactions!!
#Python note: genfromtxt only makes a 2D array if all the elements are of the same type. Otherwise what I get is called a "structured ndarray". Makes it hard to concatenate and stuff, though it can still work with np.dstack.

import glob
import numpy as np
import re
import matplotlib.pyplot as plt
import sys

def get_mass(mass_file, tp):
    fos = open(mass_file,'r')
    lines = fos.readlines()
    n_lines = len(lines)
    n_skip = 3
    i=1
    m=np.zeros(0)
    junk = "\n"
    while i < n_lines:
        temp = lines[i]
        split = temp.split(" ")
        if tp == 1:
            val = 0
            m=np.append(m,val)
        else:
            m=np.append(m,float(split[2]))
        i += n_skip
    return m

def get_energy(cube, m, iteration, N_bods):
    K = 0
    U = 0
    G = 1   #G=1 units
    for i in xrange(0,N_bods):
        dx = cube[i][iteration][2]
        dy = cube[i][iteration][3]
        dz = cube[i][iteration][4]
        r = (dx*dx + dy*dy + dz*dz)**0.5
        U -= G*m[0]*m[i+1]/r          #U_sun/massive body
        v2 = cube[i][iteration][5]**2 + cube[i][iteration][6]**2 + cube[i][iteration][7]**2
        K += 0.5*m[i+1]*v2          #KE body
        for j in xrange(i+1,N_bods):
            ddx = dx - cube[j][iteration][2]
            ddy = dy - cube[j][iteration][3]
            ddz = dz - cube[j][iteration][4]
            r = (ddx*ddx + ddy*ddy + ddz*ddz)**0.5
            U -= G*m[i+1]*m[j+1]/r    #U between bodies
    return U + K

def natural_key(string_):
    return [int(s) if s.isdigit() else s for s in re.split(r'(\d+)', string_)]

dir = sys.argv[1]
files = glob.glob(dir+'*.txt')
files = sorted(files, key=natural_key)
N_bodies = len(files)

#file 0 is the sun which is empty
cube=np.genfromtxt(files[1],delimiter='  ',dtype=float)
nr, nc = cube.shape
cube = np.reshape(cube, (1,nr,nc))

#read in data for each body
for i in xrange(2,N_bodies):
    data=np.genfromtxt(files[i],delimiter='  ',dtype=float)
    data = np.reshape(data, (1,nr,nc))
    cube = np.concatenate((cube,data),axis=0)

N_bods,N_output,N_cols = cube.shape

#get masses of each body
mp = get_mass("pl.in",0)
mtp = get_mass("tp.in",1)
m = np.concatenate([mp,mtp])    #0th slot is sun's mass!!

#calc E of system at time 0
dE = np.zeros(N_output)
time = np.zeros(N_output)
E0 = get_energy(cube,m,0,N_bods)
for i in xrange(0,N_output):
    E = get_energy(cube,m,i,N_bods)
    dE[i] = np.fabs((E - E0)/E0)
    time[i] = cube[0][i][0]

plt.plot(time, dE, 'o')
plt.yscale('log')
plt.xscale('log')
plt.savefig(dir+'Energy.png')
plt.show()
