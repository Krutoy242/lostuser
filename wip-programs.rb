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
