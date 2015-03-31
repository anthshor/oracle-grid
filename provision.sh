# v0.1 Initial

# PreInstall requirements
# Install grid software
# Referred to 12c Oracle Install Guide and http://en.wikibooks.org/wiki/RAC_Attack_-_Oracle_Cluster_Database_at_Home 
# thanks Alvaro https://github.com/kikitux/stagefiles/blob/master/db/preinstall_crs_db.sh#L1
 
echo "installing oracle-rdbms-server-12cR1-preinstall" 
PACKAGES="oracle-rdbms-server-12cR1-preinstall openssh glibc git" 

rpm -q $PACKAGES 
if [ $? -ne 0 ]; then 
  yum clean all 
  yum -y install $PACKAGES  
fi


# Create Oracle Inventory directory

[ -d /u01/app/oraInventory ] || mkdir -p /u01/app/oraInventory


# Create the required directories

useradd -u 54322 -g oinstall -G dba grid
mkdir -p /u01/app/12.1.0/grid
mkdir -p /u01/app/grid
mkdir -p /u01/app/oracle
chown -R grid:oinstall /u01
chown oracle:oinstall /u01/app/oracle
chmod -R 775 /u01/

ORACLE_HOME=/u01/app/12.1.0/grid; export ORACLE_HOME

echo grid | passwd grid --stdin

su - grid -c 'echo "umask 022" >> .bash_profile' 


# echo deadline > /sys/block/${ASM_DISK}/queue/scheduler 

# Unpack previously downloaded grid software

if [ -d /home/grid/grid]; then
    echo "Skipping unzipping..."
  else
    su - grid -c 'unzip /vagrant/software/linuxamd64_12102_grid_1of2.zip'
    su - grid -c 'unzip /vagrant/software/linuxamd64_12102_grid_2of2.zip'
fi



# su - grid -c '/media/sf_12cR1/grid/runInstaller -silent -showProgress -promptForPassword -waitforcompletion -responseFile /vagrant/grid.rsp'


