# dnsexit-virtualmin-dns-updater
Modified DNSExit updater with additional scripts that update Virtualmin DNS records and send Pushbullet updates.

## Story
Made some changes to the DNSexit.com [updater](http://www.dnsexit.com/Direct.sv?cmd=ipClients) to allow it to notify me when the public ip address on the Virtualmin server changes and also to update the Virtualmin host DNS records.

## Files

* **/etc/dnsexitoldip** contains the old(current) ip address. This is updated to current internet ip address after updating the DNS server records on Virtualmin
* **/usr/local/sbin/dnsexitipaddresschange** sends the pushbullet messages and is called by
* **/usr/sbin/ipUpdate.pl**       to send a push when the ip address changes.
* **/usr/local/sbin/dnsexitupdatevirtualmindns** Updates the DNS records on Virtualmin after an IP address change.
* **/etc/dnsexit.conf** Configuration for your DNSexit account is saved in this file.
* **/usr/local/share/dnsexit-setup.pl** - Run this script to configure the DNS Updater with your DNSexit account information.
* **/etc/dnsexitoldip** Keeps a record of the "old" ip address until we update everything.
* **/var/log/dnsexit.log** Log file of what the script does.
* **/tmp/dnsexit-ip.txt** The DNSexit scripts temp file containing the current ip address.
* **/tmp/dnsexitpushbullet.txt** Used when sending a pushbullet message.
* **/usr/share/ipUpdate-1.6/Http_get.pm** Required by **ipUpdate.pl**.
* **ipUpdate-1.6-2.tar.gz** The original 1.6 version of the DNSexit archive for reference (can be downloaded [here](http://downloads.dnsexit.com/ipUpdate-1.6-2.tar.gz)).

## Dependencies

To send Pushbullet.com notifications you will need to setup [Pushbullet Bash](https://github.com/Red5d/pushbullet-bash).

## Setup

* **NOTE**:  This version uses a **SysV-stlye** init script. This was installed on Ubuntu 14.04 LTS. The next version will be installed on Ubuntu 16.04 LTS which uses the **systemd** startup system.
* Put the files in the appropriate locations indicated by the folder structure in the repository and ensure proper permissions.
* Run the **dnsexit-setup.pl** script to configure the updater with your DNSexit information.
* To have the Sysv start the daemon after booting run the following as  the super user:
<code style="bash">sudo update-rc.d -n ipUpdate defaults</code>
* You will also need to configure [Pushbullet Bash](https://github.com/Red5d/pushbullet-bash). See the instructions on the projects page.

## Disclaimer

I have backed these files here for future reference. I have never installed from them. It could be that some files that were installed from the original .deb package have been missed, however I have included the original archive.
