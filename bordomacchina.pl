#!/usr/bin/perl
#----------------------------------------------------------------
#Perl test application for the Elexol Ethernet IO24 device.
#Developed using Perl v5.6.1 built for i386-linux.
#
#Summary:
#	High Level Methods:
#		FindDeviceOnNetwork()
#		ConfigurePortDirection($IP_Address, $Port, "A", 0)
#		ReadPortValue($IP_Address, $Port, "a")
#		WritePortValue($IP_Address, $Port, "a", 5)
#
#	Low Level Methods:
#		OpenUDP($IP_Address, $Port)
#		ReadUDP($sock)
#
#This code may be used freely in any application provided that
#the following web site is referenced in that application:
#
#
#Comments may be sent to:
#
#Author: Geoff Collett 
#        Geoff.Collett@AcaciaLT.com.au 
#        Acacia Lateral Technologies Pty Ltd.
#        http://www.acacialt.com.au/
#
#Version 1.0  13 April 2005
#----------------------------------------------------------------
#
#);
# Use the socket library
use IO::Socket;
use DateTime;

# Automatically flush output
$| = 1;

#---------------------------------------------------------------
# Initialisation
#---------------------------------------------------------------
$Port = 2424;
$Direzione = $ARGV[0];
$Tempo = $ARGV[1];

#print "DIR: " .$Direzione."\n";
#print "Tempo: " .$Tempo."\n";

#WILLY
$IP_Address="10.10.10.10";

#print qq(
#	L'ip della card e': [$IP_Address]);

# Determine the broadcast address on this network
# Otherwise use ifconfig to see what this is
$Broadcast_Address = inet_ntoa(INADDR_BROADCAST);

# Catch signals
$SIG{HUP} = \&CloseUp; #-1
$SIG{INT} = \&CloseUp; #-2
$SIG{QUIT} = \&CloseUp; #-3
$SIG{TRAP} = \&CloseUp; #-5
$SIG{KILL} = \&CloseUp; #-9
$SIG{TERM} = \&CloseUp; #-15
$SIG{STOP} = \&CloseUp; #-17


# Search for all EIO24 devices on the network
#($IP_Address, $Device_Name, $MAC_Address, $Version) = &FindDeviceOnNetwork();
#
#print qq(
#Device IP Address  is [$IP_Address]
#Device Name        is [$Device_Name]
#Device MAC Address is [$MAC_Address]
#Device Version     is [$Version]
#
#);

#---------------------------------------------------------------
# Read the values on the ports
#---------------------------------------------------------------

#---------------------------------------------------------------
# Make port A an input (0=output, 255=input on all bits) port
#---------------------------------------------------------------
&ConfigurePortDirection($IP_Address, $Port, "A", 0);

$i=0;

#while ($i<1) {
#
&WritePortValue($IP_Address, $Port, "A", $Direzione);
# `sleep $Tempo`;
#&WritePortValue($IP_Address, $Port, "A", 0);

#$i++;

# stop
#&WritePortValue($IP_Address, $Port, "A", 96);
# avanti
#&WritePortValue($IP_Address, $Port, "A", 112);
# indietro
#&WritePortValue($IP_Address, $Port, "A", 240);
# avanti dx
#&WritePortValue($IP_Address, $Port, "A", 80);
# avanti sx
#&WritePortValue($IP_Address, $Port, "A", 48);
# indietro sx
#&WritePortValue($IP_Address, $Port, "A", 176);
# indietro dx
#&WritePortValue($IP_Address, $Port, "A", 208);




# ---- fine programma robot test ------

#converto il numero in binario per poter accedere ai singoli valori dei contatti

#da esadecimale a decimale
#$dec = hex($val);

# da decimale a binario
#$bin = unpack("B*", pack("N", $dec));

# rimuovo gli zeri iniziali
#$bin =~ s/^0+(?=\d)//;   

#$time = DateTime->now();

# stampo il valore degli otto contatti (0|1)
#print qq($val\n);



#};


exit;



#---------------------------------------------------------------
#---------------------------------------------------------------
#-------------- Supporting Subroutines Follow ------------------
#---------------------------------------------------------------
#---------------------------------------------------------------



#---------------------------------------------------------------
# Open a UDP connection to the device
#---------------------------------------------------------------
sub OpenUDP
{
	my ($IP_Address, $Port) = @_;

	#print "Connecting to EIO24 on $IP_Address:$Port\n";
	$sock = new IO::Socket::INET->new
	(
		PeerAddr => $IP_Address,
		PeerPort => $Port,
		Proto     => 'udp',
		Reuse     => 1,
		Timeout   => 5,
		Type    => SOCK_DGRAM
	) or die "Unable to connect to EIO24: $!";
	$sock->autoflush(1);
	#print "UDP Port opened to $IP_Address:$Port\n\n";

	return($sock);
}



#---------------------------------------------------------------
# Read any reply from the UDP port
#---------------------------------------------------------------
sub ReadUDP
{
	my ($sock) = @_;

	# Accept a maximum reply of 20 bytes
	my $MAXLEN=20;

	# Clear the receive buffer
	my $response = "";

	# Attempt to receive the message from the UDP socket
	$sock->recv($response, $MAXLEN);

	# Return the response to the caller
	return($response);
}

#---------------------------------------------------------------
# Catch all signals and shutdown gracefully.
#---------------------------------------------------------------
sub CloseUp
{
  my $signal = shift;

  print "Server received signal [$signal].  Shutting down.\n";
	&WritePortValue($IP_Address, $Port, "A", 0);
  exit;
}

#---------------------------------------------------------------
# Send broadcast message to find the device on the network
#---------------------------------------------------------------
sub FindDeviceOnNetwork
{
	#print "Sending broadcast to $Broadcast_Address:$Port to locate the EIO24 device\n";

	# Prepare to broadcast on the local network
	use Socket;
	socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname("udp")) or die;
	setsockopt(SOCKET, SOL_SOCKET, SO_BROADCAST, 1);
	$ip = inet_aton($Broadcast_Address);

	# Send message IO24 as broadcast
	$msg="IO24";
	send(SOCKET, $msg, 0, sockaddr_in($Port, $ip)) == length($msg) or die;
	
	# Read the response from the device
	#print "Waiting for response from card\n";
	$val = '';
	($Device_Address = recv(SOCKET, $val, 200, 0))        || die "recv: $!";

	# Determine the IP address, mac and version number
	($port, $hisiaddr) = sockaddr_in($Device_Address);
	$Device_Name = gethostbyaddr($hisiaddr, AF_INET);
	$Device_IP = inet_ntoa($hisiaddr);

	# Extract the mac address and device version number
	(@mac_bytes) = unpack("x4 H2 H2 H2 H2 H2 H2 H2", $val);
	($version) = unpack("x4 x6 H2", $val);
	$mac = join(":", @mac_bytes);
	#print "Received response from $Device_Name [$Device_IP:$port]\n";
	#print "MAC [$mac] $Version [$version]\n";
	
	# Return this information
	return($Device_IP, $Device_Name, $mac, $version);
}

#---------------------------------------------------------------
# Read the value of a port (a,b,c) and return the value
#---------------------------------------------------------------
sub ReadPortValue
{
	my ($IP_Address, $Port, $CardPort) = @_;

	# Check that a valid port was supplied
	if($CardPort !~ /[abc]/)
	{
		print "Error: you must supply a valid port of a, b or c\n";
		return -1;
	}

	# Open a connection to the device
	$sock = &OpenUDP($IP_Address, $Port);

	# Request the port data
	print $sock "$CardPort";

	# Read the value (ie Ax where A is the port and x is the data)
	$val = &ReadUDP($sock);

	# Ignore the port and read the value
	($data) = unpack("x H2", $val);

	# Close the connection
  close($sock);

	return($data);
}

#---------------------------------------------------------------
# Configure the nominated port for input (11111111) or output (00000000)
#---------------------------------------------------------------
sub ConfigurePortDirection
{
	my ($IP_Address, $Port, $CardPort, $Direction) = @_;

	# Check that a valid port was supplied
	if($CardPort !~ /[ABC]/)
	{
		print "Error: you must supply a valid port of A, B or C\n";
		return -1;
	}
	if($Direction < 0 || $Direction > 255)
	{
		print "Error: you must supply a valid port direction mask of 0 to 255\n";
		return -1;
	}

	# Open a connection to the device
	$sock = &OpenUDP($IP_Address, $Port);

	# Configure the port
	$data = pack("a a c", "!", $CardPort, $Direction);
	print $sock $data;

	# Close the connection
  close($sock);

	return(0);
}

#---------------------------------------------------------------
# Write to the nominated port
#---------------------------------------------------------------
sub WritePortValue
{
	my ($IP_Address, $Port, $CardPort, $Value) = @_;

	# Check that a valid port was supplied
	if($CardPort !~ /[ABC]/)
	{
		print "Error: you must supply a valid port of A, B or C\n";
		return -1;
	}
	if($Value < 0 || $Value > 255)
	{
		print "Error: you must supply a valid data value of 0 to 255\n";
		return -1;
	}

	# Open a connection to the device
	#print "Writing [$i] to [$IP_Address:$Port] port [$CardPort]\n";
	$sock = &OpenUDP($IP_Address, $Port);

	# Configure the port
	$data = pack("a c", $CardPort, $Value);
	print $sock $data;

	# Close the connection
  close($sock);

	return(0);
}

