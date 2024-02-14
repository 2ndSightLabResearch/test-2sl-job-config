#/bin/bash -e
# https://github.com/2slresearch/2sl-job-config
# /aws/deploy_config.sh
# author: @teriradichel @2ndsightlab
# Description: Deploy a job configuration to 
# AWS SSM Parameter Store
#
# See README.md for more information
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

  creds=$(curl -H "Authorization: $AWS_CONTAINER_AUTHORIZATION_TOKEN" $AWS_CONTAINER_CREDENTIALS_FULL_URI 2>/dev/null)

  if [ "$creds" != "" ]; then
    region=$AWS_REGION

    sudo yum install jq -y

    accesskeyid="$(echo $creds | jq -r ".AccessKeyId")"
    secretaccesskey="$(echo $creds | jq -r ".SecretAccessKey")"
    sessiontoken="$(echo $creds | jq -r ".Token")"

  else

    echo "Enter AWS CLI to deploy SSM Parameter and retrieve any required data: " 
    read PROFILE

    while [ "$PROFILE" == "" ]; do
      echo "Profile cannot be empty."
      echo "To see a list of AWS CLI Profiles run: aws configure list-profiles." 
      echo "Enter profile:"
      read PROFILE
    done
  fi

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
# GET SSM Param name, config file, and private config file name
####################### 
 ssmparam="/job/$job/$role/$config"
 configfile="$BASE-config$ssmparam"
 
 echo "Enter private configuration repository folder name."
 
 echo -e "\nAvailable repos:"
 echo "~~~~~~~~~~~~~~~~~~~~~"
 ls | grep -v $BASE'-config' | grep -v '.sh' | grep -v $BASE'-exec' | grep -v $BASE's' | grep -v $BASE'-resources'

 read privaterepo

 privatedir="$privaterepo/job/$job/$role"
 privateconfigfile="$privatedir/$config"

####################### 
# Replace placeholders in file name, if any
####################### 
 p=$(echo $privateconfigfile | sed 's/[^{{]*{{//')
 p=$(echo $p | sed 's|}}.*||')

 echo "Enter value for {{$p}}:"
 read v

 privateconfigfile=$(echo $privateconfigfile | sed "s|{{$p}}|$v|g")
 ssmparam=$(echo $ssmparam | sed "s|{{$p}}|$v|g")

 echo "Private config file name: $privateconfigfile ok? (Enter to continue, ctrl-c to exit."
 read ok

####################### 
# Copy the config file to the private config file,
# creating directories if needed
####################### 

 if [ -f $privateconfigfile ]; then 
		echo "The file $privateconfigfile already exists. Do you want to overwrite it? (y)"
    read y
		if [ "$y" != "y" ]; then exit; fi
 fi

 #create the directories if they do not already exist
 if [ ! -d $privatedir ]; then
  mkdir -p $privatedir
 fi

  #copy the file to the new repo
	cp "$configfile" "$privateconfigfile"

####################### 
# REPLACE PLACEHOLDERS IN DOUBLE BRACES {{ }}
# WITH ENVIRONMENT SPECIFIC VALUES
####################### 
  
	#if there was a placeholder in the file name,
	#replace any instances in the file
  sed -i "s|{{$p}}|$v|g" $privateconfigfile

  parse=$(cat $privateconfigfile)

  while [[ $parse == *{{* ]]; do

    p=""; v=""
    parse=$(echo $parse | sed 's/[^{{]*{{//')
    p=$(echo $parse | sed 's|}}.*||')

    if [ "$p" == "aws::region" ]; then
      v=$(get_region)
    elif [ "$p" == "aws::accountid" ]; then
      v=$(get_account_id)
    else
      echo "Enter a value for: $p"
			read v
    fi
	
    echo "$p=$v"

		#replace placeholder
		if [ "$p" != "" ]; then
			sed -i "s|{{$p}}|$v|g" $privateconfigfile
	  fi
 done

 echo "Private configuration:"
 cat $privateconfigfile
 
####################### 
# CHECK THE PRIVATE CONFIGURATION INTO THE
# PRIVATE REPOSITORY
####################### 
 echo -e "\nCheck into GitHub? (y)"
 read y

 if [ "$y" == "y" ]; then

 #Check the new configuration into the private repo
 cd $privaterepo
 pwd
 ls
 git add .
 git commit -m "Adding or updating $privateconfigfile"
 git push
 cd ..
 exit

else
	echo "Warning: configuration in SSM Parameter store may not match GitHub configuration repository."
fi

####################### 
# DEPLOY THE SSM PARAMETER
####################### 

 echo "Deploy $ssmparam to SSM Parameter Store? (y)"
 read y

 if [ "$y" == "y" ]; then
  source $BASE-resources/aws/resources/ssm/parameter/parameter_functions.sh
	
	#if env != root then we may want to add the KMS key...
  set_ssm_parameter_job_config $ssmparam $privaterepo

 fi


