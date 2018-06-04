#!/bin/bash

################################################
# Script by François YoYae GINESTE - 03/04/2018
# For monoeciCore V0.12.2.3
# https://monoeci.io/tutorial-masternode/
################################################

LOG_FILE=/tmp/install.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

clear

cat <<'FIG'
 __  __                             _
|  \/  | ___  _ __   ___   ___  ___(_)
| |\/| |/ _ \| '_ \ / _ \ / _ \/ __| |
| |  | | (_) | | | | (_) |  __/ (__| |
|_|  |_|\___/|_| |_|\___/ \___|\___|_|

FIG

# Check for systemd
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Check if executed as root user
if [[ $EUID -ne 0 ]]; then
	echo -e "This script has to be run as \033[1mroot\033[0m user"
	exit 1
fi

#print variable on a screen
decho "Make sure you double check before hitting enter !"

read -e -p "User that will run Monoeci core /!\ case sensitive /!\ : " whoami
if [[ "$whoami" == "" ]]; then
	decho "WARNING: No user entered, exiting !!!"
	exit 3
fi
if [[ "$whoami" == "root" ]]; then
	decho "WARNING: user root entered? It is recommended to use a non-root user, exiting !!!"
	exit 3
fi
read -e -p "Server IP Address : " ip
if [[ "$ip" == "" ]]; then
	decho "WARNING: No IP entered, exiting !!!"
	exit 3
fi
read -e -p "Masternode Private Key (e.g. 3bsTPBdDf3USqoAAnHmfmSyHqZ4fACkUDNezE7ZVKQyxEKiy8MK # THE KEY YOU GENERATED EARLIER) : " key
if [[ "$key" == "" ]]; then
	decho "WARNING: No masternode private key entered, exiting !!!"
	exit 3
fi
read -e -p "(Optional) Install Fail2ban? (Recommended) [Y/n] : " install_fail2ban
read -e -p "(Optional) Install UFW and configure ports? (Recommended) [Y/n] : " UFW

decho "Updating system and installing required packages."   

# update package and upgrade Ubuntu
sudo apt-get -y update >> $LOG_FILE 2>&1
sudo apt-get -y upgrade >> $LOG_FILE 2>&1
# Add Berkely PPA
decho "Installing bitcoin PPA..."

sudo apt-get -y install software-properties-common >> $LOG_FILE 2>&1
sudo apt-add-repository -y ppa:bitcoin/bitcoin >> $LOG_FILE 2>&1
sudo apt-get -y update >> $LOG_FILE 2>&1

# Install required packages
decho "Installing base packages and dependencies..."

sudo apt-get -y install >> $LOG_FILE 2>&1
sudo apt-get -y wget >> $LOG_FILE 2>&1
sudo apt-get -y git >> $LOG_FILE 2>&1
sudo apt-get -y unzip >> $LOG_FILE 2>&1
sudo apt-get -y libevent-dev >> $LOG_FILE 2>&1
sudo apt-get -y libboost-dev >> $LOG_FILE 2>&1
sudo apt-get -y libboost-chrono-dev >> $LOG_FILE 2>&1
sudo apt-get -y libboost-filesystem-dev >> $LOG_FILE 2>&1
sudo apt-get -y libboost-program-options-dev >> $LOG_FILE 2>&1
sudo apt-get -y libboost-system-dev >> $LOG_FILE 2>&1
sudo apt-get -y libboost-test-dev >> $LOG_FILE 2>&1
sudo apt-get -y libboost-thread-dev >> $LOG_FILE 2>&1
sudo apt-get -y libdb4.8-dev >> $LOG_FILE 2>&1
sudo apt-get -y libdb4.8++-dev >> $LOG_FILE 2>&1
sudo apt-get -y libminiupnpc-dev >> $LOG_FILE 2>&1
sudo apt-get -y build-essential >> $LOG_FILE 2>&1
sudo apt-get -y libtool >> $LOG_FILE 2>&1
sudo apt-get -y autotools-dev >> $LOG_FILE 2>&1
sudo apt-get -y automake >> $LOG_FILE 2>&1
sudo apt-get -y pkg-config >> $LOG_FILE 2>&1
sudo apt-get -y libssl-dev >> $LOG_FILE 2>&1
sudo apt-get -y libevent-dev >> $LOG_FILE 2>&1
sudo apt-get -y bsdmainutils >> $LOG_FILE 2>&1
sudo apt-get -y libzmq3-dev >> $LOG_FILE 2>&1
sudo apt-get -y virtualenv >> $LOG_FILE 2>&1
sudo apt-get -y pwgen >> $LOG_FILE 2>&1

decho "Optional installs (fail2ban and ufw)"
if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
	cd ~
	sudo apt-get -y install fail2ban >> $LOG_FILE 2>&1
	sudo systemctl enable fail2ban >> $LOG_FILE 2>&1
	sudo systemctl start fail2ban >> $LOG_FILE 2>&1
fi

if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
	sudo apt-get -y install ufw >> $LOG_FILE 2>&1
	sudo ufw allow ssh/tcp >> $LOG_FILE 2>&1
	sudo ufw allow sftp/tcp >> $LOG_FILE 2>&1
	sudo ufw allow 24156/tcp >> $LOG_FILE 2>&1
	sudo ufw allow 24157/tcp >> $LOG_FILE 2>&1
	sudo ufw default deny incoming >> $LOG_FILE 2>&1
	sudo ufw default allow outgoing >> $LOG_FILE 2>&1
	sudo ufw logging on >> $LOG_FILE 2>&1
	sudo ufw enable --force >> $LOG_FILE 2>&1
fi

#Create user (if necessary)
getent passwd $whoami > /dev/null 2&>1
if [ $? -ne 0 ]; then
	sudo adduser --disabled-password --gecos "" $whoami >> $LOG_FILE 2>&1
fi

#Create monoeci.conf
decho "Setting up monoeci Core" 
#Generating Random Passwords
user=`pwgen -s 16 1`
password=`pwgen -s 64 1`

mkdir -p /home/$whoami/.monoeciCore/
cat << EOF > /home/$whoami/.monoeciCore/monoeci.conf
rpcuser=$user
rpcpassword=$password
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
maxconnections=24
masternode=1
masternodeprivkey=$key
externalip=$ip
EOF
sudo chown -R $whoami:$whoami /home/$whoami

echo 'monoeci.conf created'

#Install Moneoci Daemon
cd
wget https://github.com/monacocoin-net/monoeci-core/releases/download/v0.12.2.3/monoeciCore-0.12.2.3-linux64.tar.gz >> $LOG_FILE 2>&1
sudo tar xvzf monoeciCore-0.12.2.3-linux64.tar.gz >> $LOG_FILE 2>&1
sudo cp monoeciCore-0.12.2/bin/monoecid /usr/bin/ >> $LOG_FILE 2>&1
sudo cp monoeciCore-0.12.2/bin/monoeci-cli /usr/bin/ >> $LOG_FILE 2>&1
sudo cp monoeciCore-0.12.2/bin/monoeci-tx /usr/bin/ >> $LOG_FILE 2>&1
rm -rf monoeciCore-0.12.2 >> $LOG_FILE 2>&1

#Run monoecid as selected user
sudo -H -u $whoami bash -c 'monoecid' >> $LOG_FILE 2>&1

echo 'Monoeci Core prepared and lunched'

sleep 10

#Setting up coin

decho "Setting up sentinel"

#Install Sentinel
git clone https://github.com/monacocoin-net/sentinel.git /home/$whoami/sentinel >> $LOG_FILE 2>&1
sudo chown -R $whoami:$whoami /home/$whoami/sentinel >> $LOG_FILE 2>&1

cd /home/$whoami/sentinel
sudo -H -u $whoami bash -c 'virtualenv ./venv' >> $LOG_FILE 2>&1
sudo -H -u $whoami bash -c './venv/bin/pip install -r requirements.txt' >> $LOG_FILE 2>&1

#Setup crontab
echo "@reboot sleep 30 && monoecid" >> newCrontab
echo "* * * * * cd /home/$whoami/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> newCrontab
crontab -u $whoami newCrontab >> $LOG_FILE 2>&1
rm newCrontab >> $LOG_FILE 2>&1

decho "Starting your masternode"
echo ""
echo "Now, you need to finally start your masternode in the following order: "
echo "1- Go to your windows/mac wallet and modify masternode.conf as required, then restart and from the Masternode tab"
echo "2- Select the newly created masternode and then click on start-alias."
echo "3- Once completed, please return to VPS and wait for the wallet to be synced."
echo "4- Then you can try the command 'monoeci-cli masternode status' to get the masternode status."

su $whoami
