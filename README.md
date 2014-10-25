# WarpSpeed Server Provisioning and Management

We make web deployment easy. For complete information, please visit: http://warpspeed.io

## Server Provisioning

WarpSpeed is designed for use with Ubuntu 14.04 LTS. A variety of installer scripts are available within this repository to configure your server just as you want it. The scripts in this repository can be used standalone, or in conjunction with the WarpSpeed.io web interface (coming soon).

### WarpSpeed.io Web Interface (Coming Soon)

WarpSpeed.io will allow you to use all of these scripts very easily through a intuitive web interface. You will be able to connect to your favorite server provider, create a server, install your stack, and deploy your first site with just a few clicks.

### Standalone Usage

To use the WarpSpeed scripts in a standalone fashion, you first need to create a server. You can use a server like RackSpace, Digital Ocean, Linode, etc. to create your server. Make sure you use an Ubuntu 14.04 LTS base image, regardless of your server provider.

Once you have created your server, log in as root and run the following command:

<pre>
wget -O warpspeed-provisioner.sh https://raw.githubusercontent.com/warpspeed/warpspeed/master/provision-manual.sh; bash warpspeed-provisioner.sh
</pre>

The manual provisioner will ask a few questions. Be prepared with an SSH public key to use for authentication to the server. You will also be able to customize what stack is installed on your server. Look in the `installers` folder of this repository to see what options are available.

Once your server is provisioned, you should be able to SSH to your server without using a password by typing the following at your terminal:

<pre>
ssh warpspeed@server-ip-here
</pre>

## Server Management

Once provisioned, you can easily manage your server with the `warpspeed` command. All options will be available via the WarpSpeed.io web interface or by using the scripts manually on your server. Just type `warpspeed` after you have logged into your server and you will see this:

<pre>
Usage: warpspeed [COMMAND] [PARAMS] [OPTIONS]...
  This is the WarpSpeed.io server management utility.
  For complete information, visit: warpspeed.io.

Available commands:

  site:create [TYPE] [NAME] [OPTIONS]...
  site:remove [NAME]
  site:reload [NAME]
  site:update [NAME]

  mysql:db [DBNAME] [USER] [PASS]
  mysql:backup [DBNAME]

  postgres:db [DBNAME] [USER] [PASS]
  postgres:backup [DBNAME]

  update
</pre>

For complete information on available commands please visit http://warpspeed.io.

## License

&copy; Turner Logic, LLC. Distributed under the GNU GPL v2.0.
