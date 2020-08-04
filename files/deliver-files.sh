#!/bin/sh

wget https://raw.githubusercontent.com/Financial-Times/eks-files/master/upp-customizations.sh -O /tmp/upp-customizations.sh
bash -x /tmp/upp-customizations.sh
