#!/usr/bin/perl -w
###################################################
##
##  DnsExit.Com Dynamic IP update script
##  v1.6
##
##################################################

use Http_get;

$PROGRAMDIR=`dirname $0`;
chop $PROGRAMDIR;
chdir($PROGRAMDIR) || die "Unable to go to dir $PROGRAMDIR";

#
# Get config variables
#
$cfile = "/etc/dnsexit.conf";
open (CFG, "< $cfile") || (print STDERR "Fail open config file $cfile. You need to run dns-setup.pl script" && exit );
while (<CFG>)
{
  (my $line = $_ ) =~ s/\s+$//;

  if ( length( $line ) < 2 || ( $line =~ /^\s*#/ ) )
  {
    next;
  }
  ($key, $value) = split(/=/, $line);
  $keyVal{$key} = $value;
}
$ipfile   = $keyVal{"cachefile"} || '/tmp/dnsexit-ip.txt';
$pidfile  = $keyVal{"pidfile"} || '/var/run/ipUpdate.pid';
$daemon   = lc($keyVal{"daemon"}) || 'yes';
$interval = $keyVal{"interval"} || 600;
$logfile  = $keyVal{"logfile"} || '/var/log/dnsexit.log';


if ( ! ( $daemon eq "yes" ) )
{
  clear();
  $ip = getProxyIP();
  
  $ipFlag = isIpChanged($ip);
  if ( $ipFlag == 1 )
  {
    mark("INFO", "100", "IP is not changed from last successful update");
# To change when Pushbullet sends updates about the ip changing or not, edit /usr/local/sbin/dnsexitipaddresschange.
      my $changed = 0;
      system('/usr/local/sbin/dnsexitipaddresschange', "$ip", "$changed");
    exit 0;
  }
  postNewIP( $ip );
    my $changed = 1;
    system('/usr/local/sbin/dnsexitipaddresschange', "$ip", "$changed");
    system('/usr/local/sbin/dnsexitupdatevirtualmindns');
    }
  else
{
  daemonize();
  while(1)
  {
    clear();
    mark("INFO", "100", "Started in daemon mode");
    my $changed = 0;
    $ip = getProxyIP();  
    system('/usr/local/sbin/dnsexitipaddresschange', "$ip", "$changed");
    $ipFlag = isIpChanged($ip);
    if ( $ipFlag == 1 )
    {
      mark("INFO", "100", "IP is not changed from last successful update");
    } 
    else
    {
      postNewIP( $ip );
    }
    sleep( $interval );
  }
}
exit 0;
#-----------------------------------------------------
#-- Sub Routines
#-----------------------------------------------------
sub postNewIP
{
  my $newip = shift ( @_ );
  my $get = new Http_get;
  my $url = $keyVal{"url"};
  my $login = $keyVal{"login"};
  my $password = $keyVal{"password"};
  my $host = $keyVal{"host"};
  my $posturl = "${url}?login=${login}&password=${password}&host=${host}";

  if ( $newip =~ /\d+\.\d+\.\d+\.\d+/ )
  {
    $posturl = ${posturl} . "&myip=${newip}";
  }

  my $response = $get->request($posturl);
  if ($response->is_success)
  {
    #record successful update of the ip address
    
    $result = $response->content;    
    if ( $result =~ /(\d+)=(.+)/ )
    {
      mark("Success", "$1", "$2");
      open S, "> $ipfile";
      print S $ip;
      close S;
    }
    else
    {
      mark("ERROR", "-99", "Return content format error");
    }

  }
  else
  {
    mark("ERROR", $response->code, $response->message);
  }

}

sub isIpChanged
{
  my $newip = shift(@_);
  open SS, "< $ipfile";
  my $preip = <SS>;
  close SS;
  #print "new=[$newip] old=[$preip]";
  if (!($newip eq $preip))
  {
    return 0;
  }
  return 1;
}
sub getProxyIP
{
  my $get = new Http_get;
  my $ipServs = $keyVal{"proxyservs"};
  my @servs = split(/;/, $ipServs);
  foreach $server ( @servs )
  {
    $myUrl = "http://" . $server;
    
    $response = $get->request($myUrl);
    if ($response->is_success)
    {
    	if ( $response->content =~ /\D*(\d+\.\d+\.\d+\.\d+).*/ )
    	{
    		mark("INFO", "100", "$myUrl says your IP address is: $1");
    		return ( $1 );
    	}
    	else
    	{
    		mark("ERROR", "-100", "Return message format error.... Fail to grep the IP address from ".$myUrl);
    	}
    }
  }
  mark("ERROR", "-99", "Fail to get the proxy IP of your machine");
  return "";
}
sub mark
{
    my ($type, $code, $message) = @_;
    open (LOGFILE, ">>$logfile");
    my $msg=localtime()."\t$type\t".$code."\t".$message."\n";
    print $msg;
    print LOGFILE $msg;
    close LOGFILE;
}
sub clear
{
    open (LOGFILE, "> $logfile");
    close LOGFILE;
}

# Daemonize the process and write pid to pidfile
sub daemonize {
  open (STDIN, '/dev/null')   or die "Can't read /dev/null: $!";
  open (STDOUT, '>>/dev/null') or die "Can't write to /dev/null: $!";
  open (STDERR, '>>/dev/null') or die "Can't write to /dev/null: $!";
  defined(my $pid = fork)   or die "Can't fork: $!";
  if ($pid ) {
    open (PIDFILE, ">$pidfile");
    print PIDFILE $pid;
    close PIDFILE;
    exit;
  }
  umask 0;
}
