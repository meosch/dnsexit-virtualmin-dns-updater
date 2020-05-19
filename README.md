# dnsexit-virtualmin-dns-updater
Modified DNSExit updater with additional scripts that update Virtualmin DNS records and send Email updates.

## Story
Made some changes to the DNSexit.com [updater](http://www.dnsexit.com/Direct.sv?cmd=ipClients) to allow it to notify me when the public ip address on the Virtualmin server changes and also to update the Virtualmin host DNS records.

## Files

* **/tmp/dnsexit-oldip.txt** contains the old ip address. This is saved when it is seen the current ip address and the ExitDNS DNS ip adresses do not match.
* **/usr/local/sbin/dnsexitipaddresschange** sends the email messages and is called by
* **/usr/sbin/ipUpdate.pl** to send an email when the ip address changes.
* **/usr/local/sbin/dnsexitupdatevirtualmindns** Updates the DNS records on Virtualmin after an IP address change.
* **/etc/dnsexit.conf** Configuration for your DNSexit account is saved in this file.
* **/usr/local/share/dnsexit-setup.pl** - Run this script to configure the DNS Updater with your DNSexit account information.
* **/etc/dnsexitoldip** Keeps a record of the "old" ip address until we update everything.
* **/var/log/dnsexit.log** Log file of what the script does.
* **/tmp/dnsexit-ip.txt** The DNSexit scripts temp file containing the current ip address.
* **/tmp/dnsexitemail.txt** Used when sending an email message.
* **/usr/share/ipUpdate-1.6/Http_get.pm** Required by **ipUpdate.pl**.
* **/home/username/bin/ta.sh** Script to send messages via Telegram on IP changes.
* **ipUpdate-1.6-2.tar.gz** The original 1.6 version of the DNSexit archive for reference (can be downloaded [here](http://downloads.dnsexit.com/ipUpdate-1.6-2.tar.gz)).


## Setup

* **NOTE**: This version was installed on Ubuntu 16.04 LTS which uses a **systemd** startup system script. A previous version used a **SysV-stlye** init script and was installed on Ubuntu 14.04 LTS. See the releases section for a previous release that has **sysv** in the release tag.
* Put the files in the appropriate locations indicated by the folder structure in the repository and ensure proper permissions.
* Run the **dnsexit-setup.pl** script to configure the updater with your DNSexit information.
* To have the have **systemd** start the daemon after booting run the following as  the super user:

<code style="bash">sudo systemctl enable ipupdate-dnsexit.service</code>

* If you previously had the **sysv** startup script installed be sure to remove it from **/etc/init.d/ipUpdate**. This will prevent the service from being run twice under two different names.

* Note: Previously this project used Pushbullet to send out messages of ip changes. This proved to be unreliable, so updates are now sent via email and Telegram. This means you need an email server like postfix and should setup aliases that point to external email addresses unless you plan to read these emails on the server.

## Disclaimer

I have backed these files here for future reference. I have never installed from them. It could be that some files that were installed from the original .deb package have been missed, however I have included the original archive.
