
USER=warpspeed

# If the vagrant home directory exists, assume we are using vagrant.
if [ -d "/home/vagrant" ]; then
	USER=vagrant
fi

apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties

cd /usr/local
git clone git://github.com/sstephenson/rbenv.git rbenv
git clone git://github.com/sstephenson/ruby-build.git rbenv/plugins/ruby-build

chown -R $USER:$USER rbenv
