#!/bin/bash -e
# https://github.com/2ndSightLabResearch/2sl-job-exec
# /init_config.sh
# author: @tradichel @2ndsightlab
# Description: Download the code required to deploy a
# job configuration to an SSM Parameter for the 
# 2nd Sight Lab Job Execution Framework
#####################################################

d=`basename "$PWD"`
base=$(echo $d | sed 's|-exec||')

########################
# warn if in wrong directory and offer
# to move to correct directory
########################

if [ "$d" == $base'-exec' ] || [ -f "README.md" ]; then
  echo "You are in this directory:"
  echo $d
  echo -e "\nIt appears you may be executing this file from the repository"
  echo "directory. You need to execute it from the folder one level up"
  echo "that contains all four 2SL Job Exec Framework repositories."
  echo "Would you like to copy the file one level? (y)"
  read y
  if [ "$y" == "y" ]; then
    cp init_config.sh ../
    echo "File successfully copied. Changing to directory one level up."
    cd ..
    sh -c "./init_config.sh"
  fi
  exit
fi

echo -e "\nDo you want to use the test version of the repos?"
echo "The test repos start with test- in front of the names above."
echo "Type 'test' (no quotes) to use the test version otherwise type enter."
read test

if [ "$test" == "test" ]; then test="test-"; else test=""; fi

PARENT_FOLDER=$test'2sl-job'
if [ "$base" != $PARENT_FOLDER ]; then
  echo "You need to clone the repositories into a folder named"
  echo "$PARENT_FOLDER. Do you want to create that directory? (y)"
  read create
  if [ "$create" == "y" ]; then
    if [ -d $PARENT_FOLDER ]; then
      echo "Parent folder $PARENT_FOLDER already exists."
      echo "Do you want to delete it and everything in it it to proceed? (y for yes or enter to continue)"
      read delete
      if [ "$delete" == "y" ]; then
        echo "Deleteing $PARENT_FOLDER ok? (Crtl-c to exit)"
        read ok
        rm -rf $PARENT_FOLDER
      else
        create="n"
      fi
    fi
    if [ "$create" == "y" ]; then
      mkdir $PARENT_FOLDER
    fi
  fi
fi

cd $PARENT_FOLDER

REPO_CONFIG=$test'2sl-job-config'
REPO_RESOURCES=$test'2sl-job-resources'

echo "Repositories to be cloned. Enter to continue, ctrl-c to exit."
echo $REPO_CONFIG
echo $REPO_RESOURCES
read ok

if [ -d $REPO_CONFIG ]; then 

	echo "$REPO_CONFIG already exists"; 
	echo "Do you want to delete it? (y)"
	read y

	if [ "$y" == "y" ]; then
		rm -rf $REPO_CONFIG		
	fi

fi

if [ ! -d $REPO_CONFIG ]; then
	git clone 'https://github.com/2ndSightLabResearch/'$REPO_CONFIG'.git'
fi

if [ -d $REPO_RESOURCES ]; then

  echo "$REPO_RESOURCES already exists";
  echo "Do you want to delete it? (y)"
  read y
  
  if [ "$y" == "y" ]; then
    rm -rf $REPO_RESOURCES
  fi

fi

if [ ! -d $REPO_RESOURCES ]; then
  git clone 'https://github.com/2ndSightLabResearch/'$REPO_RESOURCES'.git'
fi

echo "You need a repository for your private job configurations with"
echo "organization and environment specific values."
echo "Enter the URL for your private github repository:"
read privaterepourl

privaterepodir=$(echo $privaterepourl | cut -d "/" -f5 | sed "s|.git||")

if [ ! -d $privaterepodir ]; then 
  git clone $privaterepourl
fi

echo "You now have the required code to configure jobs."
echo 'To create a private configuration run this script: '$REPO_CONFIG'/create_config.sh'
echo 'To deploy the configuration with an AWS Access Key stored in Secrets Manager run this script: '$REPO_CONFIG'/deploy_config.sh'

