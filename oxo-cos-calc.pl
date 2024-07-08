#!/usr/bin/perl
# David, July 2024


# ---- hier Werte anpassen ---
# Teilnehmer Verbindungskategorie (normal oder eingeschr.)
my $sub_lc = "8";

# Teilnehmer Rufnummernsperre 
my $sub_blc = "4";

# Buendel Verkehrsaufteilung
my $trunk_lc = "1";

# Buendel Rufnummernsperre
my $trunk_blc = "1";

# gerufene Nummer
my $dialed = "0345123456789";

my $bt_counter1 = "22";
my $bt_counter2 = "4";


my @ts_matrix = ( [ "traffic sharing matrix" ],
	[ 1,  "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+" ],
	[ 2,  "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", " " ],
	[ 3,  "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", " ", " " ],
	[ 4,  "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", " ", " ", " " ],
	[ 5,  "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", " ", " ", " ", " " ],
	[ 6,  "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", " ", " ", " ", " ", " " ],
	[ 7,  "+", "+", "+", "+", "+", "+", "+", "+", "+", "+", " ", " ", " ", " ", " ", " " ],
	[ 8,  "+", "+", "+", "+", "+", "+", "+", "+", "+", " ", " ", " ", " ", " ", " ", " " ],
	[ 9,  "+", "+", "+", "+", "+", "+", "+", "+", " ", " ", " ", " ", " ", " ", " ", " " ],
	[ 10, "+", "+", "+", "+", "+", "+", "+", " ", " ", " ", " ", " ", " ", " ", " ", " " ],
	[ 11, "+", "+", "+", "+", "+", "+", " ", " ", " ", " ", " ", " ", " ", " ", " ", " " ],
	[ 12, "+", "+", "+", "+", "+", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " " ],
	[ 13, "+", "+", "+", "+", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " " ],
	[ 14, "+", "+", "+", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " " ],
	[ 15, "+", "+", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " " ],
	[ 16, "+", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " " ],
);

my @barring_matrix = ( ["barring matrix" ],
	[  1, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4 ],
	[  2, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5 ],
	[  3, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6 ],
	[  4, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1 ],
	[  5, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2 ],
	[  6, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3 ],
	[  7, "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0" ,"0" ],
	[  8, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5 ],
	[  9, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6 ],
	[ 10, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1 ],
	[ 11, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2 ],
	[ 12, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3 ],
	[ 13, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4 ],
	[ 14, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5 ],
	[ 15, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6 ],
	[ 16, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6, 1 ] );

@barring_level = ( { "prefix" => "forbidden/allowed" },
	{
		"#" => "forbidden",
		"*" => "forbidden",
	    	"0" => "forbidden",
	   	"1" => "forbidden",
	   	"2" => "forbidden",
	    	"3" => "forbidden",
	   	"4" => "forbidden",
	   	"5" => "forbidden",
	   	"6" => "forbidden",
	   	"7" => "forbidden",
	   	"8" => "forbidden",
	   	"9" => "forbidden" },
	 {
		"0" => "forbidden" },
	 {
		"00" => "forbidden",
		"010" => "forbidden",
		"013" => "forbidden",
		"0900" => "forbidden" },
	 {
		"010" => "forbidden",
		"013" => "forbidden",
		"019" => "forbidden",
		"0999" => "allowed",
		"0900" => "forbidden" },
	 {
		"00" => "forbidden" },
	 {
		"00" => "forbidden" } );

# ----
my $lc_permission = { "+" => "allowed",
		      " " => "disallowed" };
my $barring_table = $barring_matrix[$sub_blc][$trunk_blc]; 
print "Subscriber is ";
print $lc_permission->{$ts_matrix[$sub_lc][$trunk_lc]} ." to allocate Trunk\n";

print "Number dialing is carried by barring table: $barring_table\n";

for my $key (keys %{$barring_level[$barring_table]}) {
	$cos_right = $barring_level[$barring_table]->{$key}; 
	if ( $cos_right eq "allowed" and $dialed =~ m/^$key/ ) {
		if ( length($dialed) < $bt_counter1 ) {
			print "dialing of $dialed is allowed.\n";
		} else {
			print "dialing of $dialed is forbidden because C1 is reached.\n";
			exit;
		}
	} elsif ( $cos_right eq "forbidden" and $dialed =~ m/$key/ ) {
		print "dialing of $dialed forbidden because prefix \"$key\".\n";
		exit;
	} elsif ( length($dialing) > $bt_counter2 ) {
		print "C2 reached, dialing of $dialed is forbidden.\n";
	}
	print "$key => \"$cos_right\" ";
	if ($dialed =~ m/^$key/) {
		print " .. $cos_right\n";
	} else {
		print " ... no match\n";
	}
}
print "dialing of $dialed is allowed. \n";

