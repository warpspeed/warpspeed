
USER=warpspeed

# If the vagrant home directory exists, assume we are using vagrant.
if [ -d "/home/vagrant" ]; then
	USER=vagrant
fi

apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties

cd /usr/local
git clone git://github.com/sstephenson/rbenv.git rbenv
git clone git://github.com/sstephenson/ruby-build.git rbenv/plugins/ruby-build

export PATH="/usr/local/rbenv/bin:/usr/local/rbenv/plugins/ruby-build/bin:$PATH"
eval "$(rbenv init -)"

rbenv install 2.1.3
rbenv global 2.1.3

chown -R $USER:$USER rbenv
