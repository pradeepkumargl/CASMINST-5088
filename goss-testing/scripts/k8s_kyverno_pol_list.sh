#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
print_results=0
while getopts ph stack
do
    case "${stack}" in
          p) print_results=1;;
          h) echo "usage: k8s_kyverno_pol_list.sh           # Only print 'PASS' upon success"
             echo "       k8s_kyverno_pol_list.sh -p        # Print all results and errors if found. Use for manual check."
             exit 3;;
         \?) echo "usage: k8s_kyverno_pol_list.sh           # Only print 'PASS' upon success"
             echo "       k8s_kyverno_pol_list.sh -p        # Print all results and errors if found. Use for manual check."
             exit 3;;
    esac
done

error_flag=0

# checks if kyverno policies are loaded

number_of_policies=$(kubectl get pol -A | wc | awk '{print $1}')
if [[ $number_of_policies -lt 1 ]] || [[ $number_of_policies -eq 1 ]]
then
              if [[ $print_results -eq 1 ]]; then echo "Error: No Kyverno policies are loaded"; fi
              error_flag=1;                   
fi
              
if [[ error_flag -eq 0 ]]; then echo "PASS"; exit 0;
else echo "FAIL"; exit 1; 
fi
