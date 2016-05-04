#!/usr/bin/perl -w
###################################################
##
##  DnsExit.Com Dynamic IP update setup script
##  v1.6
##
##################################################

use Http_get;
use strict;

my $cfile = '/etc/dnsexit.conf';
my $geturlfrom = 'http://www.dnsexit.com/ipupdate/dyndata.txt';
my $proxyservs = 'ip.dnsexit.com;ip2.dnsexit.com;ip3.dnsexit.com';
my $logfile = '/var/log/dnsexit.log';
my $cachefile = '/tmp/dnsexit-ip.txt';
my $pidfile = '/var/run/ipUpdate.pid';

my $URL_VALIDATE='http://www.dnsexit.com/ipupdate/account_validate.jsp';
my $URL_DOMAINS='http://www.dnsexit.com/ipupdate/domains.jsp';
my $URL_HOSTS='http://www.dnsexit.com/ipupdate/hosts.jsp';

my $MSG_WELCOME= "Wecome in DnsExit.Com Dynamic IP update setup script.\n".
                 "Please follow instructions to setup our script.\n\n";
my $MSG_USERNAME="Please type username you have created on www.dnsexit.com (blank to leave setup):\n";
my $MSG_PASSWORD="Please type password for your username:\n";
my $MSG_CHECKING_USERPASS="Checking your username and password...\n";
my $MSG_CHECKING_DOMAINS="Checking your registered domains. This may take a while...\n\n";
my $MSG_USERPASSOK="Username and password correct...\n\n";
my $MSG_HOSTS="Please type password for your username:\n";
my $MSG_SELECT_DOMAINS="Please select your domains (if you want to select more than\n".
                       "one domain, please separete them by space):\n";
my $MSG_SELECT_DOMAINS_AFTER="Your selection: ";
my $MSG_FETCHING_HOSTS="Feching hosts in your domains. This may take a while...\n";
my $MSG_SELECT_HOSTS="Please select host you want to be updated (if you want to \n".
                       "select more than one domain, please separete them by space):\n";
my $MSG_SELECT_HOSTS_AFTER="Your selection: ";
my $MSG_YOU_HAVE_SELECTED="You have selected following hosts to be updated:\n";
my $MSG_SELECT_PROXY="If you want to use the IP address of your proxy server instead of the\n".
                     "IP of the local host, set the value to \"yes\"\n";
my $MSG_PROXY_SEL="Your choice [no]: ";
my $MSG_SELECT_DAEMON="Do you want to run it as a daemon?\n";
my $MSG_DAEMON_SEL="Your choice [yes]: ";
my $MSG_SELECT_INTERVAL="How often (in minutes) should the program check IP change?\n".
                        "It will only be posted to dnsExit.com when IP address is\n".
                        "changed from the last update. It need to be at least 3 minutes.\n";
my $MSG_INTERVAL_SEL="Your choice [10]: ";
my $MSG_INTERVAL_TOLOW="Interval too low. It need to be at least 3 minutes.\n";
my $MSG_SELECT_PIDFILE="Select path to pidfile.\n";
my $MSG_PIDFILE_SEL="Your choice [/var/run/ipUpdate.pid]: ";
my $MSG_PIDFILE_BAD="You have selected invalid file name.\n";
my $MSG_GENERATING_CFG="Generating config file...";
my $MSG_DONE="Done creating config file. You can run the script now.\n".
             "To do it you can run ipUpdate.pl or use init script.\n\n".
             "File '$cachefile' will cache the ip address of\n".
             "the last successful IP update to our system. For next\n".
             "update, if the IP stays the same, the update request\n".
             "won't be sent to our server. You can simply change the\n".
             "IP at dnsexit-ip.txt file to force the update to DNSEXIT.\n\n";
my $MSG_PATHS="Here are paths to some intresting files:\n";
my $MSG_END="Don't forget to read README.txt file in doc directory!\n";


my $ERR_DOMAINS="Can't get list of your domains from the server";
my $ERR_NO_DOMAINS="You don't have any domain registered. You should login to your control panel ".
                  "at www.dnsexit.com and register some domain.\n";
my $ERR_NO_DOMAINS_SELECTED="You have not selected any domains. Exiting...\n";
my $ERR_NO_HOSTS_SELECTED="You have not selected any hosts. Exiting...\n";
my $ERR_NO_URL="Can't fetach url info from dnsexit.com. Please try again later...\n";

my $get = new Http_get;
print $MSG_WELCOME;

#
# Delete ald cache file
#
unlink $cachefile;

#
# Get url from dnsexit.com
#
my $url;
$get->request($geturlfrom);
if($get->is_success) {
	my $result = $get->content;
	if ( $result =~ /url=(.+)/ ) {
		$url=$1;
		if((my $chr=chop($url)) ne "\n"){
			$url.=$chr;
		}
	}
}
if(!$url) {
	print $ERR_NO_URL;
	exit;
}
#
# Get username/password and validate it.
#
my $userpassok=0;
my $message=undef;
my $username;
my $password;
do {
	if($message) {
		print "\nError: $message\n\n";
	}
	# Get username
	print $MSG_USERNAME;
	$username=<STDIN>;
	chop $username;
	if($username eq "") { exit; };

	# Get password
	print $MSG_PASSWORD;
	$password=<STDIN>;
	chop $password;

	print $MSG_CHECKING_USERPASS;
	# Check username/password
	$get->request($URL_VALIDATE."?login=$username&password=$password");
	if($get->is_success) {
		my $result = $get->content;
		if ( $result =~ /(\d+)=(.+)/ ) {
			$userpassok=$1;
			$message=$2;
			if((my $chr=chop($message)) ne "\n"){
				$message.=$chr;
			}
		}
	}
} until($userpassok==0);
print $MSG_USERPASSOK;

#
# Get list of domains and ask user which of them should be explored
#
my @domains;
print $MSG_CHECKING_DOMAINS;
$get->request($URL_DOMAINS."?login=$username&password=$password");
if($get->is_success) {
	my $result = $get->content;
	if ( $result =~ /(\d+)=(.+)/ ) {
		$message=$2;
		if((my $code=$1)==0) {
			@domains=split(/ +/, $message);
		}
		elsif($code==1) {
			print "\n$ERR_NO_DOMAINS\n\n";
			exit;
		}
		else {
			print"\nError: $message\n\n";
			exit;
		}
	}
	else {
		print "\n$ERR_DOMAINS\n\n";
		exit;
	}
}
else {
	print "\n$ERR_DOMAINS\n\n";
	exit;
}

print $MSG_SELECT_DOMAINS;
my @hosts;
my $i=0;
my @domainno;
foreach my $domain (@domains) {
	$domain =~ s/\s+//g;
	next if $domain eq "";
	print $i." $domain\n";
	$domainno[$i++]=$domain;
}
print $MSG_SELECT_DOMAINS_AFTER;


#
# Get list of hosts from selected domains and ask user which should be added
# to the config file.
#
my $line=<STDIN>;
my $check=$line;
$check =~ s/\s+//g;
if($check eq "") {
	print $ERR_NO_DOMAINS_SELECTED;
	exit;
}
my @tofilter=split(/ +/, $line);
my @selected;
foreach my $fil (@tofilter) {
	$fil =~ s/\s+//g;
	next if $fil eq "";
	if($domainno[$fil]) {
		push @selected, $fil;
	}
}
if(!@selected) {
	print $ERR_NO_DOMAINS_SELECTED;
	exit;
}
print $MSG_FETCHING_HOSTS;
foreach my $select (@selected) {
	my $domain=$domainno[$select];
	$get->request($URL_HOSTS."?login=$username&password=$password&domain=$domain");
	if($get->is_success) {
		my $result=$get->content;
		if ( $result =~ /(\d+)=(.+)/ ) {
			$message=$2;
			if((my $code=$1)==0) {
			my @myhosts=split(/\ /, $message);
				foreach my $host (@myhosts) {
					$host =~ s/\s+//g;
					push (@hosts,$host);
				}
			}
		}
	}
}

print $MSG_SELECT_HOSTS;
$i=0;
foreach my $host (@hosts) {
	print $i." $host\n";
	$domainno[$i++]=$host;
}
print $MSG_SELECT_DOMAINS_AFTER;

$line=<STDIN>;
$check=$line;
$check =~ s/\s+//g;
if($check eq "") {
	print $ERR_NO_HOSTS_SELECTED;
	exit;
}
@tofilter=split(/ +/, $line);
my @select;
foreach my $fil (@tofilter) {
	$fil =~ s/\s+//g;
	next if $fil eq "";
	if($domainno[$fil]) {
		push @select, $fil;
	}
}
if(!@select) {
	print $ERR_NO_HOSTS_SELECTED;
	exit;
}
my $hosts;
print "\n".$MSG_YOU_HAVE_SELECTED;
foreach my $sel (@select) {
	$sel =~ s/\s+//g;	
	print "$domainno[$sel]\n";
	$hosts.=$domainno[$sel];
	$hosts.=';';
}
print "\n";
chop $hosts;

#
# Ask user whants daemon mode.
#
print "\n";
print $MSG_SELECT_DAEMON;
my $daemon='';
do {
	print $MSG_DAEMON_SEL;
	$daemon=<STDIN>;
	if($daemon eq "\n") {
		$daemon='yes';
	}
	else {
		$daemon=lc($daemon);
		if((my $chr=chop($daemon)) ne "\n"){
			$daemon.=$chr;
		}
	}
} until $daemon eq 'yes' || $daemon eq 'no';

#
# If deamon=YES then ask for an interval
#
my $interval;
if($daemon eq 'yes') {
	print "\n";
	print $MSG_SELECT_INTERVAL;
	do {
		print $MSG_INTERVAL_SEL;
		$interval=<STDIN>;
		if($interval eq "\n") {
			$interval='10';
		}
		elsif (! ($interval =~ /^[0-9]+$/)) {
			$interval=undef;	
		}
		elsif( $interval<3) {
			$interval=undef;	
			print $MSG_INTERVAL_TOLOW;

		}
		else {
			if((my $chr=chop($interval)) ne "\n"){
				$interval.=$chr;
			}
		}
		$interval*=60;

	} until $interval ;
}
else {
	$interval='';
}

#
# Generate config file
#
print "\n".$MSG_GENERATING_CFG;
open (CFG, "> $cfile") || die "Fail open config file $cfile. Please check if have proper permissions.";
print CFG "login=$username\n";
print CFG "password=$password\n";
print CFG "host=$hosts\n";
print CFG "daemon=$daemon\n";
print CFG "interval=$interval\n";
print CFG "proxyservs=$proxyservs\n";
print CFG "pidfile=$pidfile\n";
print CFG "logfile=$logfile\n";
print CFG "cachefile=$cachefile\n";
print CFG "url=$url\n";

close(CFG);
print "\n".$MSG_DONE;
print $MSG_PATHS;
print "Pid file: $pidfile\n";
print "Log file: $logfile\n";
print "Cache file: $cachefile\n";
print "\n".$MSG_END;
