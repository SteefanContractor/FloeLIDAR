#!/bin/bash


function usage() {
    cat <<USAGE

    Usage: $0 [-n --name] [-m --mambapath] [--skip-confirmations]

    Options:
	-n, --name:	      name of the tensorflow-gpu enabled environment you wish to create
        -m, --mambapath:      path to mambaforge/miniforge installation without the trailing slash
        --skip-confirmations: skip mamba/script prompts to continue 

    Preconfig:
	The script is intended for users who would like to create a separate gpu enabled tensorflow
	environment for each project/repository. 
	The script assumes users have packages (e.g. numpy
	, scipy etc.) installed in the base conda/mamba enviroment that are used by all projects/r-
	-epositories.
	The script also assumes you have a mambaforge/miniforge installation. The script can also
	work with anaconda/miniconda by simply replacing the mamba commands with conda equivalents.
	Note that in some cases the conda-forge channel must be explicitely specified to install t-
	-he latest package versions with conda.

    Author:
	Steefan Contractor. Contact s.contractor@unsw.edu.au to report any bugs.
	
USAGE
    exit 1
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

ENV_NAME=
PATH_TO_MAMBAFORGE=
NO_CONFIRMATION=false

while [ "$1" != "" ]; do
    case $1 in
    -n | --name)
	shift
        ENV_NAME=$1
	;;
    -m | --mambapath)
	shift
	PATH_TO_MAMBAFORGE=$1
	;;
    --skip-confirmations)
        NO_CONFIRMATION=true
        ;;
    -h | --help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
    esac
    shift
done

if [[ $ENV_NAME == "" ]]; then
    echo "You must provide an environment name";
    exit 1;
fi

if [[ $PATH_TO_MAMBAFORGE == "" ]]; then
    echo "You must provide a path to the conda/mamba installation";
    exit 1;
fi


echo Creating conda/mamba environment called $ENV_NAME
echo with all packages in base, 
echo plus latest tensorflow packages \(tensorflow and tensorboard\),
echo and compatible gpu packages \(tensorflow-gpu cudotoolkit=11.2 and cudnn=8.1.0\).
echo tensorflow-gpu is installed with pip as the latest version is unavailable on conda-forge/anaconda channels.
echo base packages will be updated before cloning into new environment.
echo Use \'Y\' \(case sensitive\) for confirmations.
echo

if [ "$NO_CONFIRMATION" = true ]; then 
	echo You have chosen to install all packages without confirmation. Are you sure about this?
else
	echo Confirmation will be required before each step.
fi

read -n 1 -p "To continue press Y: " cont
echo
if [ "$cont" = "Y" ]; then
	echo "Continuing..."
	echo
	# update all base packages
	echo Updating base packages...
	if [ "$NO_CONFIRMATION" = true ]; then
		mamba update --all --yes
	else
		mamba update --all
	fi			

	echo Creating new environment
	# create environment by cloning base
	if [ "$NO_CONFIRMATION" = true ]; then
                mamba create -n $ENV_NAME --clone base --yes
		#mamba install -n FloeLIDAR conda mamba --yes
        else
                mamba create -n $ENV_NAME --clone base
		#mamba install -n FloeLIDAR conda mamba
        fi

	echo Activating new environment
	source "$PATH_TO_MAMBAFORGE"/etc/profile.d/conda.sh
	conda activate $ENV_NAME
	
	echo Installing tensorflow and tensorboard
	# install tf packages
	if [ "$NO_CONFIRMATION" = true ]; then
		mamba install -n $ENV_NAME "tensorflow>=2.5.0" tensorboard --yes
        else
                mamba install -n $ENV_NAME "tensorflow>=2.5.0" tensorboard
        fi

	echo Installing CUDA Toolkit, cuDNN and tensorflow-gpu
	# install tf-gpu packages
	if [ "$NO_CONFIRMATION" = true ]; then
                mamba install -n $ENV_NAME cudatoolkit=11.2 cudnn=8.1.0 --yes
		pip install tensorflow-gpu
        else
                mamba install -n $ENV_NAME cudatoolkit=11.2 cudnn=8.1.0
		read -n 1 -p "Install tensorflow-gpu with pip?: " cont2
		if [ "$cont2" = "Y" ]; then pip install tensorflow-gpu; fi
        fi
	echo
	echo Finished installing all packages.
	read -n 1 -p "Deactivate $ENV_NAME environment?: " cont3
	if [ "$cont3" = "Y" ]; then conda deactivate; fi 
	echo 
	echo Exiting.
 
else
	echo "Quitting program"
fi



