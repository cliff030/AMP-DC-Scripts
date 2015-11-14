#!perl
use strict;
use warnings;
use Switch::Plain;
use Text::CSV_XS;

binmode STDOUT, ":utf8";

my $csv_path = "C:\\Scripts\\Resources\\Document Imaging\\";
my $file_path;
my $cmd;
my $company;

for (my $i = 0; $i <=1; $i++) {
	$company=$i;
	
	if($i==0) {
		for(my $j = 0; $j <= 1; $j++) {
			$file_path = set_path($j);
			my @csv = get_csv($j);
			foreach(@csv) {
				unless(-e $file_path.$_."\\Scanned documents\"") {
					$cmd = "MD \"".$file_path.$_."\\Scanned documents\"";
					system("$cmd");
				}
			}
		}
	} else {
		for(my $j = 0; $j <= 3; $j++) {
			$file_path = set_path($j);
			my @csv = get_csv($j);
			foreach(@csv) {
				unless(-e $file_path.$_) {
					$cmd = "MD \"".$file_path.$_."\"";
					system("$cmd");
				}
			}
		}
	}
}

sub set_path {
	my $req = $_[0];
	my ($path, $client_path, $lead_path, $issues_path, $creditors_path);	

	if ($company==0) {
		$path = "\\\\AMP\\Select Financial\\Reports\\";
		$client_path = $path."Client";
		$lead_path = $path."Lead";
	} elsif($company==1) {
		$path = "\\\\AMP\\Liberty Financial\\Scanned Documents\\";
		$client_path = $path."Clients\\";
		$lead_path = $path."Leads\\";
		$issues_path = $path."Issues\\";
		$creditors_path = $path."Creditors\\";
	} else {
		die ("Invalid Company!");
	}

	nswitch($req) {
		case 0: {
			$file_path = $client_path;
		}
		case 1: {
			$file_path = $lead_path;
		}
		case 2: {
			$file_path = $creditors_path;
		}
		case 3: {
			$file_path = $issues_path;
		}
	}

	return $file_path;
}

sub get_csv {
	my $req = $_[0];
	my @ids;
	my $file;
	my @rows;

	nswitch($req) {
		case 0: {
			if($company==0) {
				$file = "select_clients.csv";
			} elsif($company==1) {
				$file = "liberty_clients.csv";
			}
		}
		case 1: {
			if($company==0) {
				$file = "select_leads.csv";
			} elsif($company==1) {
				$file = "liberty_leads.csv";
			}
		}
		case 2: {
			$file = "liberty_creditors.csv";
		}
		case 3: {
			$file = "liberty_issues.csv";
		}
	}
	$file = $csv_path.$file;

	my $csv = Text::CSV_XS->new ({ binary => 1, blank_is_undef => 1, empty_is_undef => 1 }) or
		die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
	open my $fh, "<:encoding(utf8)", "$file" or die "$file: $!";
	
	while (my $row = $csv->getline ($fh)) {
	     push @rows, $row;
	}
	
	$csv->eof or $csv->error_diag();
	close $fh;
	
	for(my $i = 0; $i <= $#rows; $i++) {
		if($rows[$i][0]) {
			if($rows[$i][0] =~ m/\d/) {
				$rows[$i][0] =~ s/\D//g;
				push @ids, $rows[$i][0];
			}
		}
	}
	return @ids;
}
