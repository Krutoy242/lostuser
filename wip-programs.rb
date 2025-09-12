# ? Oredict filtering robot
IsF/3&i255ⓐRd(1&IgSII!.o'({ore=1,dus=0})[sg.s(v,1,3)]'ⓞ3)

# ? Drone sapling planter
x,z=i%8,i%64//8 u={x,0,z} # Coords base on `i` variable
Gs(x,z)[32]==0 # Is air 1 layer down
_'Dm(v[1],0,v[2]),s!,Dp0'/{u,u*'-v'} # Move to point, place, and come back

x,z=i%8,i%64//8 u={x,0,z}∅_"_'Dm*u,s!,Dp0'/{u,u*'-v'}"~'Gs(x,z)[32]'
Gs(1,1,-1,8,8,1)*"v~=0ⓞ_'Dm(k,0,v)s!Dp(0)Dm(-k,0,-v)s!'(k%8,k/8)"
a=-1,Gs_11a881

# ?========================================================
# Unstackable extractor

(IgSI/3&_a^i117ⓞ{}).mS^_{_'IsF/3&a,Rd1ⓞ{Pp1,Rsel9,Rp1,Rsel1,Rd1}'}
(IgSI/3&_a^i117ⓞ{}).mS^_{IsF/3/a|'Pp1,sel9,p1,d^sel1'/R~-Rd/1}
'(IgSI-3-_a/i117).mS'&_{IsF/3/a-'Pp1,sel9,p1,d^sel1'/R~-Rd/1}

(IgSI/3&_a^i117ⓞ{}).mS^_{IsF/3/a|'Pp1,sel9,p1,d^sel1'/R~-Rd/1}

IgSI(3,k).mS^_{IsF/3/k|'Pp1,sel9,Rp1,Rd^sel1'/R~-Rd/1}

_"IgSI(3,_a^i117).mS^_{IsF/3/a|'Pp1,sel9,Rp1,Rd^sel1'/R~-Rd/1}"

IgSI(3,_a^i117).mS^_{IsF/3/a|'Pp1,sel9,Rp1,Rd^sel1'/R~-Rd/1}

# ?========================================================
# Cyclic miner but with blocks

# With infinity placing block
Gi,_'Rm3,Rp3,Rsw3,Rp0'~i*2.25,Rtn⒯

# Twilight Forest Bedrock
Gi,_'~(Rsw/0),Rsw3,Rm3'~i*0.5,Rtn⒯

# ?========================================================
# Hammer Leveller
# Cobble in front, Mechanical Crafter with Sharpening Kits under
Rsw3,i%99==0ⓐ{Ie!,_a(I23^1).mD-a.d<20ⓐ{Rd0,s2,Rsk0},Ie!}

# ?========================================================
# Flower gatherer
# 0 slot: petal, 1 slot: empty, 2 slot: Kama, 3+ slots: fertilizer
Ru3,Ie!,_a⒯,_'aⓐRc&k+2>0ⓐ{R16&k+2,Ie!,Ru3,Ie!,_a⒡,Rsel1,Ie!}'~14

Ru3,Ie!,Ru3,R16&2,Ie!,Rsw3

R16/(i%3+1)-Ie-i/_{Ru,Ru,Rsw}/3-Ie
R16(i%3+1),Ie!,i/_{Ru,Ru,Rsw}&3,Ie!
_m(i%3+1),R16^m,Ie!,({Ru,Ru,Rsw})[m]&3,Ie!
