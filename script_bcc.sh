#!/bin/bash
#Batch script to run quantum-espresso with iterations for bcc

#lattic parameter
a=5.981361131

#No. of iterations, total iterations = iter*2+1
iter=3

#Amount by which lattic parameter should change
incVal=0.1

n=-$iter
new_a=$a
echo "a,Total_energy">data.csv
echo "">ev.in

while [ $n -le $iter ]
do
	new_a=$(echo "$a + $incVal * $n" | bc -l)



cat > sample.pw.in <<EOF
 &CONTROL
                 calculation = 'scf' ,
                      outdir = './' ,
                      wfcdir = './' ,
                  pseudo_dir = './' ,
                     tstress = .true. ,
                     tprnfor = .true. ,
                     
                      
 /
 &SYSTEM
                       ibrav = 3,
                   celldm(1) = ${new_a},
                         nat = 1,
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
   W  183.84  W_pbe_v1.2.uspp.F.UPF
ATOMIC_POSITIONS alat 
   W      0.0    0.0    0.0   
       
K_POINTS automatic 
  20 20 20   1 1 1 


EOF

	echo "Calculating for a=$new_a"
	mpirun -np 2 pw.x <sample.pw.in> sample${n}.pw.out

	strTotalE="$(grep ! sample${n}.pw.out)"
        totalE=$(echo $strTotalE | grep -Eo '[+-]?[0-9]+([.][0-9]+)?')
        echo "$new_a,$totalE">>data.csv
        echo "$new_a $totalE">>ev.in
	n=$(( n+1 ))	 # increments $n
done

echo "Now run ev.x using ev.in as input"
