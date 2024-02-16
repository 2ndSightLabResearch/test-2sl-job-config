#/bin/bash -e
# https://github.com/2slresearch/2sl-job-config
# deploy_config.sh
# author: @teriradichel @2ndsightlab
# Description: Deploy a job configuration to 
# AWS SSM Parameter Store
##############################################################

d=`basename "$PWD"`
BASE=$(echo $d | sed 's|-config||')

####################### 
# warn if in wrong directory and offer
# to move to correct directory
######################## 

if [ "$d" != "$BASE" ]; then

  echo -e "\nIt appears you may be executing this file from the repository"
  echo "directory. You need to execute it from the folder that contains"
	echo "the four repositories. Would you like to copy this file to that"
	echo "folder and execute it? (y)"
  read y

  if [ "$y" == "y" ]; then
    cp deploy_config.sh ..
    echo "File successfully copied. Changing to directory one level up."
    cd ..
   	p=`basename "$PWD"`
    if [ "$p" != "$BASE" ]; then 
			echo "Error: the four repositories should be in a directory named $BASE not $p."
			exit 1
		fi
		sh -c "./deploy_config.sh"
  fi
  exit
fi

####################### 
# MAKE SURE PROFILE IS SET AS WILL BE USED BY COMMANDS BELOW
######################## 

#check for CloudShell credentials
if [ "$PROFILE" == "" ]; then
    echo "Enter AWS CLI to deploy SSM Parameter and retrieve any required data: " 
    read PROFILE

    while [ "$PROFILE" == "" ]; do
      echo "Profile cannot be empty."
      echo "To see a list of AWS CLI Profiles run: aws configure list-profiles." 
      echo "Enter profile:"
      read PROFILE
    done
fi

####################### 
# SET DIRECTORIES AND SOURCE REQUIRED FILES
####################### 
configrepo=$BASE'-config'
configdir=$configrepo'/job/'

source $BASE-exec/aws/shared/functions.sh
source $BASE-exec/aws/shared/validate.sh

####################### 
# WALK THE CONFIG DIR TO GET CONFIG TO DEPLOY
####################### 
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Deploy job configuration"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Available job configurations:"

echo "----------------------------"
ls $configdir | grep -v "sh"
echo -e "\nEnter job name:"
read job
while [ "$job" == "" ]; do echo "You must enter a job:"; read job; done

echo "Roles that can run this job:"
echo "----------------------------"
ls $configdir'/'$job

echo -e "\nEnter role name:"
read role
while [ "$role" == "" ]; do echo "You must enter a role:"; read role; done

echo -e "\nAvailable Configurations:"
echo "----------------------------"
ls $configdir'/'$job'/'$role

echo -e "\nEnter configuration:"
read config
while [ "$config" == "" ]; do echo "You must enter a configuration:"; read config; done
 
####################### 
# DEPLOY THE SSM PARAMETER
####################### 

 echo "Deploy $ssmparam to SSM Parameter Store? (y)"
 read y

 if [ "$y" == "y" ]; then
  source $BASE-resources/aws/resources/ssm/parameter/parameter_functions.sh
  set_ssm_parameter_job_config $ssmparam $privaterepo
 fi


