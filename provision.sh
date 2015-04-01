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


# Create the required user, groups and directories

[ `grep asmadmin /etc/group | wc -l` -ne 0 ] || groupadd -g 54328 asmadmin
[ `grep asmoper /etc/group | wc -l` -ne 0 ] || groupadd -g 54329 asmoper
[ `grep asmdba /etc/group | wc -l` -ne 0 ] || groupadd -g 54325 asmdba

id grid 2> /dev/null
if [ $? -ne 0 ]; then
  useradd -u 54322 -g oinstall -G asmadmin,asmdba,asmoper grid
fi
[ -d /u01/app/12.1.0/grid ] || mkdir -p /u01/app/12.1.0/grid
[ -d /u01/app/grid ] || mkdir -p /u01/app/grid
[ -d /u01/app/oracle ] || mkdir -p /u01/app/oracle
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
if [ $? -ne 0 ]; then
  echo "Failed to unzip files. Permissions issue?"
  exit
fi

# Create partition table and write it to disk

for disk in sdc sdd ; do
fdisk /dev/$disk  << EOF
n
p
1
1

w
EOF
done
if [ $? -ne 0 ]; then
  echo "Something went wrong with fdisk"
  exit
fi

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
 RESULT=="`$cmd /dev/$disk`", NAME="asm-disk$i", OWNER="grid", GROUP="asmdba", MODE="0660"
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

# Add hostname to hosts file. 

if [ `grep -i $hostname /etc/hosts | wc -l` -ne 0 ]; then
    echo "Skipping modifying hosts file, hostname present"
  else
    long="`hostname`"
    short="`hostname -s`"
    echo "updating /etc/hosts with $HOSTNAME information"
    if [ "$short" == "$long" ]; then
      echo "127.0.0.1 localhost.localdomain localhost $short" > /etc/hosts
    else
      echo "127.0.0.1 localhost.localdomain localhost $long $short" > /etc/hosts
    fi
fi

# Set hard and soft limits
echo "grid 		soft    nofile          4096" >> /etc/security/limits.conf
echo "grid		hard    nofile          65536" >> /etc/security/limits.conf
su - grid -c 'ulimit -n 65536'

#su - grid -c 'grid/runInstaller -silent -showProgress -promptForPassword -waitforcompletion -responseFile /vagrant/grid.rsp'
su - grid -c 'grid/runInstaller -silent -showProgress -promptForPassword -waitforcompletion -responseFile /vagrant/grid.rsp'

# Run root scripts
su - root -c '/u01/app/oraInventory/orainstRoot.sh'
su - root -c '/u01/app/12.1.0/grid/root.sh'
