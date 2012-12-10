#!/bin/bash
s[1]=100
s[2]=400
s[3]=1600
s[4]=6400
for i in {1..4}
do
  echo "ruby ../main.rb -ar -t 0.2 e_rep${s[i]}.txt > results/rep${s[i]}_redres_e2.txt"
  ruby ../main.rb -ar -t 0.2 e_rep${s[i]}.txt > results/rep${s[i]}_redres_e2.txt
  echo "ruby ../main.rb -ar -t 0.2 gen${s[i]}.txt > results/gen${s[i]}_redres_e2.txt"
  ruby ../main.rb -ar -t 0.2 gen${s[i]}.txt > results/gen${s[i]}_redres_e2.txt
done
