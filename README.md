# WarpSpeed Server Provisioning and Management

We make web deployment easy. For complete information, please visit: [https://warpspeed.io](https://warpspeed.io "WarpSpeed.io").

## Server Provisioning

WarpSpeed is designed for use with Ubuntu 22.04 LTS 64 bit. A variety of installer scripts are available within this repository to configure your server just as you want it. The scripts in this repository can be used standalone, or in conjunction with the [WarpSpeed.io](https://warpspeed.io "WarpSpeed.io") web interface.

### Usage

To use the WarpSpeed scripts, you first need to create a server. You can use a server like [RackSpace](http://www.rackspace.com/cloud/servers "RackSpace"), [Digital Ocean](https://www.digitalocean.com/?refcode=e8387d479043 "Digital Ocean"), [Linode](https://www.linode.com/?r=bed2c06e157de72a8f97d0c7035069800c9b342b "Linode"), etc. to create your server. Make sure you use an Ubuntu 22.04 LTS 64 bit base image, regardless of your server provider.

Once you have created your server, log in as root and run the following command:

<pre>
wget -O warpspeed-provisioner.sh https://raw.githubusercontent.com/warpspeed/warpspeed/master/provision-manual.sh; bash warpspeed-provisioner.sh
</pre>

The manual provisioner will ask a few questions. Be prepared with an SSH public key to use for authentication to the server. You will also be able to customize what stack is installed on your server. Look in the `installers` folder of this repository to see what options are available.

If you don't already have an SSH key set up, follow this great guide here: https://help.github.com/articles/generating-ssh-keys/.

Once your server is provisioned, you should be able to SSH to your server by typing the following at your terminal:

<pre>
ssh warpspeed@server-ip-here
</pre>

## Server Management

Once provisioned, you can easily manage your server with the `warpspeed` command. Just type `warpspeed` after you have logged into your server and you will see this:

<pre>
Usage: warpspeed [COMMAND] [PARAMS] [OPTIONS]...
  This is the WarpSpeed.io server management utility.
  For complete information, visit: warpspeed.io.

Available commands:

  site:create [TYPE] [NAME] [OPTIONS]...
  site:remove [NAME] [OPTIONS]...
  site:reload [NAME]
  site:secure [NAME]

  mysql:db [DBNAME] [USER] [PASS]
  mysql:backup [DBNAME]

  postgres:db [DBNAME] [USER] [PASS]
  postgres:backup [DBNAME]

  update
</pre>

The `TYPE` for the `site:create` command can be any of the following:

<pre>
html
php
go
</pre>

The `OPTIONS` for the `site:create` command can be any of the following:

<pre>
--force     # Forces overwrite of existing configuration for a site folder that is already present.
--push      # Creates a push repository so that code can be push deployed.
--wildcard  # Setups us wildcards for nginx so that the site will respond to *.domain.com
</pre>

The `OPTIONS` for the `site:remove` command can be any of the following:
  
<pre>
--all      # Remove both the site and git repo folder matching passed NAME
</pre>



For complete information on available commands please visit: [https://warpspeed.io](https://warpspeed.io "WarpSpeed.io").

## License

&copy; [Turner Logic, LLC](http://turnerlogic.com "Turner Logic"). Distributed under the GNU GPL v2.0.
