while getopts ":v:d:a:e:g:i:m:p:cqst" opt; do
  case $opt in
    v ) # Moodle version, optional. Default is master
      MDL_VERSION=$OPTARG;;
    a ) # Admin password, required
      MDL_ADMINPASS=$OPTARG;;
    d ) # Database password, required
      MDL_DBPASS=$OPTARG;;
    e ) # Email, required
      MDL_EMAIL=$OPTARG;;
    i ) # IP address, required
      IP_ADDR=$OPTARG;;
    g ) # Gateway IP, required
      IP_GATEWAY=$OPTARG;;
    m ) # IP mask, optional. Default is 24
      IP_MASK=OPTARG;;
    p ) # Postgres version, optional. Default is 12
      MDL_POSTGRES_VERSION=$OPTARG;;
    c ) # Should install CapQuiz, optional
      CAPQUIZ=yes;;
    q ) # Should install QTracker, optional
      QTRACKER=yes;;
    s ) # Should install Stack, optional
      STACK=yes;;
    t ) # Should install ShortMath, optional
      SHORTMATH=yes;;
    
    
  esac
done

## 1 | SET STATIC IP ##
sudo bash -c "echo 'network:'                                           >> /etc/netplan/network.yaml"
sudo bash -c "echo '  version: 2'                                       >> /etc/netplan/network.yaml"
sudo bash -c "echo '  ethernets:'                                       >> /etc/netplan/network.yaml"
sudo bash -c "echo '    eth1:'                                          >> /etc/netplan/network.yaml"
sudo bash -c "echo '      addresses: [$IP_ADDR/${IP_MASK-24}]'          >> /etc/netplan/network.yaml"
sudo bash -c "echo '      gateway4: $IP_GATEWAY'                        >> /etc/netplan/network.yaml"
sudo bash -c "echo '      nameservers:'                                 >> /etc/netplan/network.yaml"
sudo bash -c "echo '        addresses: [$IP_GATEWAY, 1.1.1.1, 1.0.0.1]' >> /etc/netplan/network.yaml"
sudo netplan apply

## 2 | INSTALL DEPENDENCIES ##
sudo add-apt-repository -y ppa:ondrej/php
sudo add-apt-repository -y ppa:ondrej/apache2
sudo apt update
sudo apt install -y apache2 postgresql php phppgadmin php-pear php-curl php-zip php-gd php-intl php-soap php-yaml php-xmlrpc php-mbstring

## 3 | CONFIGURE INSTALLED DEPENDENCIES ##
# 3.1 Postgres
sudo -u postgres psql -c "CREATE USER moodleuser WITH PASSWORD '$MDL_DBPASS'";
sudo -u postgres psql -c "CREATE DATABASE moodle WITH OWNER moodleuser";
sudo bash -c "echo 'host all all 0.0.0.0/0 trust' >> /etc/postgresql/${MDL_POSTGRES_VERSION-12}/main/pg_hba.conf"

# 3.2 Apache & PHP
# Moodle requires at least 5000 input vars
sudo sed -i 's/;max_input_vars = 1000/max_input_vars = 10000/' /etc/php/8.0/cli/php.ini
sudo sed -i 's/;max_input_vars = 1000/max_input_vars = 10000/' /etc/php/8.0/apache2/php.ini
# Change DocumentRoot and ServerAdmin
sudo sed -i -e "s/webmaster@localhost/$MDL_EMAIL/" -e "s@/var/www/html@/var/www/moodle@" /etc/apache2/sites-available/000-default.conf
sudo systemctl restart apache2

## 4 | DOWNLOAD MOODLE AND OPTIONAL MODS/QTYPES/... ##
# 4.1 Make data directory
sudo mkdir /var/moodledata
sudo chown www-data /var/moodledata

# 4.2 Clone moodle
git clone --recursive --branch ${MDL_VERSION-master} https://github.com/moodle/moodle.git /var/www/moodle

# 4.3 Configure moodle
cp /var/www/moodle/config-dist.php /var/www/moodle/config.php
# Original lines: $CFG->dbname    = 'moodle';
#                 $CFG->dbuser    = 'username';
#                 $CFG->dbpass    = 'password';
#                 $CFG->wwwroot   = 'http://example.com/moodle';
#                 $CFG->dataroot  = '/home/example/moodledata';
sed -i -e s/'username/'moodleuser/ -e "s/'password/'$MDL_DBPASS/" -e "s@example.com/moodle@$IP_ADDR@" -e s@'home/example/moodledata@'var/moodledata@ /var/www/moodle/config.php
# Original lines: // $CFG->debug = (E_ALL | E_STRICT);
#                 // $CFG->debugdisplay = 1;
#                 // $CFG->cachejs = false
#                 // $CFG->cachetemplates = false;
sed -i -e 's@// $CFG->debug @$CFG->debug @' -e 's@// $CFG->debugdisplay @$CFG->debugdisplay @' -e 's@// $CFG->cachejs @$CFG->cachejs @' -e 's@// $CFG->cachetemplates @$CFG->cachetemplates @' /var/www/moodle/config.php
sudo chown -R root:www-data /var/www/

# 4.4 Download optional Moodle plugins
if [[ -n $CAPQUIZ ]]; then
  git clone https://github.com/KQMATH/moodle-mod_capquiz.git /var/www/moodle/
fi

if [[ -n $STACK ]]; then
  # THIS MIGHT SUDDENLY BREAK IN THE FUTURE
  # Download tools to build Maxima from source
  sudo apt install -y build-essential texinfo sbcl unzip

  # Download and install Maxima from source
  wget http://kent.dl.sourceforge.net/project/maxima/Maxima-source/5.44.0-source/maxima-5.44.0.tar.gz -O ~/maxima.tar.gz && sudo tar -xf ~/maxima.tar.gz -C ~/; rm ~/maxima.tar.gz
  (cd ~/maxima-5.44.0/ && sudo bash -c "./configure --with-sbcl && make && make install")
  rm -rf /home/ubuntu/maxima-5.44.0

  # Download and install question behaviours
  wget https://moodle.org/plugins/download.php/23028/qbehaviour_adaptivemultipart_moodle39_2020103000.zip -O ~/temp.zip && sudo unzip -d /var/www/moodle/question/behaviour/ ~/temp.zip; rm ~/temp.zip
  wget https://moodle.org/plugins/download.php/17558/qbehaviour_dfexplicitvaildate_moodle39_2018080600.zip -O ~/temp.zip && sudo unzip -d /var/www/moodle/question/behaviour/ ~/temp.zip; rm ~/temp.zip
  wget https://moodle.org/plugins/download.php/17559/qbehaviour_dfcbmexplicitvaildate_moodle39_2018080600.zip -O ~/temp.zip && sudo unzip -d /var/www/moodle/question/behaviour/ ~/temp.zip; rm ~/temp.zip

  # Download stack
  git clone https://github.com/KQMATH/moodle-qtype_stack.git /var/www/moodle/question/type/stack
fi

if [[ -n $QTRACKER ]]; then
  git clone https://github.com/KQMATH/moodle-local_qtracker.git /var/www/moodle/local/qtracker
fi

if [[ -n $SHORTMATH ]]; then
  git clone https://github.com/KQMATH/moodle-qtype_shortmath.git /var/www/moodle/question/type/shortmath
fi

## 5 | RUN INSTALL_DATABASE.PHP ##

sudo -u www-data php /var/www/moodle/admin/cli/install_database.php --agree-license --adminemail=$MDL_EMAIL --fullname="KQMATH Moodle Server" --shortname="KQMATH" --summary="Server for the KQMATH (Classroom Quiz) moodle plugin" --adminpass=$MDL_ADMINPASS