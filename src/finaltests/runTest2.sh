#!/bin/bash
s[1]=100
s[2]=400
s[3]=1600
s[4]=6400
s[5]=12800
s[6]=25600
t[1]=0.1
t[2]=0.2
t[3]=0.4
to[1]=1
to[2]=2
to[3]=4
for i in {1..6}
do
  for j in {1..3}
  do
  echo "ruby ../main.rb -ae -t ${t[j]} gen${s[i]}.txt > results/gen${s[i]}_res_e${to[j]}.txt"
  ruby ../main.rb -ae -t ${t[j]} gen${s[i]}.txt > results/gen${s[i]}_res_e${to[j]}.txt
  done
done
