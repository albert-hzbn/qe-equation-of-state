#!/bin/bash
#Batch script to run quantum-espresso with iterations for hcp

#Provide values of a and c
a=6.1075948
c=9.7264204

#No. of iterations, total iterations = iter*2+1
iter=3

#Amount by which volume should change
incVal=10

ratio=$(echo "$c/$a" | bc -l)
const=1.7320508075688772

n=-$iter
vol=$(echo "$const/2*$a*$a*$c" | bc -l)

echo "Volume,c/a,c,a,Total_energy">data.csv

echo "">ev.in

while [ $n -le $iter ]
do
	
    newVol=$(echo "$vol+$incVal*$n" | bc -l)
    new_a=$(echo "e(l(($newVol*2/($const*$ratio)))/3)" | bc -l)
    
    

#replace sample.pw.in file with yours
cat > sample.pw.in <<EOF
 &CONTROL
                 calculation = 'scf' ,
                      outdir = './' ,
                      pseudo_dir = './' ,
                     tstress = .true. ,
                     tprnfor = .true. ,
                     
                      
 /
 &SYSTEM
                       ibrav = 4,
                   celldm(1) = ${new_a},
                   celldm(3) = ${ratio},
                         nat = 2,
                        ntyp = 1,
                     ecutwfc = 100 ,
                     ecutrho = 400 ,
                 occupations = 'smearing' ,
                     degauss = 0.01 ,
                    smearing = 'marzari-vanderbilt' ,
 /
 &ELECTRONS
                    conv_thr = 1.0d-6 ,
                 
 /
ATOMIC_SPECIES
   Zr  91.224  Zr_pbe_v1.uspp.F.UPF
ATOMIC_POSITIONS {crystal} 
   Zr 0.33333333 0.66666666 0.25
   Zr 0.66666666 0.33333333 0.75 
       
K_POINTS automatic 
  20 20 20   1 1 1 


EOF

	echo "Calculating for volume=$newVol"
	mpirun -np 2 pw.x <sample.pw.in> sample${n}.pw.out

	strTotalE="$(grep ! sample${n}.pw.out)"
        totalE=$(echo $strTotalE | grep -Eo '[+-]?[0-9]+([.][0-9]+)?')
        echo "$newVol,$ratio,$c,$a,$totalE">>data.csv
	echo "$newVol    $totalE">>ev.in

	n=$(( n+1 ))	 # increments $n
done

echo "Calcuations completed"
echo "Now run ev.x using ev.in as input"
