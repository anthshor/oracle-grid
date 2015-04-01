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

id grid
if [ $? -ne 0 ]; then
  useradd -u 54322 -g oinstall -G dba grid
fi
[ -d /u01/app/12.1.0/grid ] || mkdir -p /u01/app/12.1.0/grid
[ -d /u01/app/12.1.0/grid ] || mkdir -p /u01/app/grid
[ -d /u01/app/12.1.0/grid ] || mkdir -p /u01/app/oracle
if [ `du -s /u01/app/ | cut -f 1` -gt 1000000 ]; then
  echo "Seems something is installed, skipping permission change"
else
  chown -R grid:oinstall /u01
  chown oracle:oinstall /u01/app/oracle
  chmod -R 775 /u01/
fi


ORACLE_HOME=/u01/app/12.1.0/grid; export ORACLE_HOME

echo grid | passwd grid --stdin

su - grid -c '[ `grep "umask 022" .bash_profile | wc -l` -ne 0 ] || echo "umask 022" >> .bash_profile' 


# echo deadline > /sys/block/${ASM_DISK}/queue/scheduler 

# Unpack previously downloaded grid software

if [ -d /home/grid/grid ]; then
    echo "Skipping unzipping..."
  else
    su - grid -c 'unzip /vagrant/software/linuxamd64_12102_grid_1of2.zip'
    su - grid -c 'unzip /vagrant/software/linuxamd64_12102_grid_2of2.zip'
fi

# Create partition table and write it to disk

fdisk /dev/sdc  << EOF
n
p
1
1

w
EOF

fdisk /dev/sdd  << EOF
n
p
1
1

w
EOF

###############

# Thanks RAC Attack 
#  - http://en.wikibooks.org/wiki/RAC_Attack_-_Oracle_Cluster_Database_at_Home/RAC_Attack_12c/Configure_Storage_Persistent_Naming

# Configure the option -g for the scsi_id command to expect an UUID

echo "options=-g" > /etc/scsi_id.config

# Prepare the file /etc/udev/rules.d/99-oracle-asmdevices.rules

i=1
cmd="/sbin/scsi_id -g -u -d"
for disk in sdc sdd ; do 
         cat <<EOF >> /etc/udev/rules.d/99-oracle-asmdevices.rules
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="$cmd /dev/\$parent", \
 RESULT=="`$cmd /dev/$disk`", NAME="asm-disk$i", OWNER="oracle", GROUP="dba", MODE="0660"
EOF
         i=$(($i+1)) 
done

# Reload the udev rules and restart udev:

/sbin/partprobe /dev/sdc1 /dev/sdd1
/sbin/udevadm test /block/sdc/sdc1
/sbin/udevadm test /block/sdd/sdd1
/sbin/udevadm control --reload-rules
/sbin/start_udev

###############

# su - grid -c '/media/sf_12cR1/grid/runInstaller -silent -showProgress -promptForPassword -waitforcompletion -responseFile /vagrant/grid.rsp'


