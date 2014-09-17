#! /usr/bin/perl -w

use strict;
use warnings;
use Switch;

sub calculateMinorAllele
{
	my ($arr) = @_;
	
	my $zeroCount = 0;
	my $oneCount = 0;
	
	for (my $i = 9; $i < int(@{$arr}); $i++)
	{
		my @tmp = split(/\:/,$arr->[$i]);
		
		my ($thisZeroCount,$thisOneCount) = countAllele($tmp[0]);
		
		$zeroCount = $zeroCount + $thisZeroCount;
		$oneCount = $oneCount + $thisOneCount;
	}
	
	my $minorAllele = 0;
				 
	if ($zeroCount > $oneCount)
	{
		$minorAllele = 1;
	}
	
	return ($zeroCount,$oneCount,$minorAllele);
}

sub countAllele
{
	my ($txt) = @_;

	my $tt  = $txt;
	my $zeroCount = ($tt =~ s/0/#/g);
	
	if ($zeroCount eq "")
	{
		$zeroCount = 0;
	}
	
	$tt = $txt;
	my $oneCount = ($tt =~ s/1/#/g);
	
	if ($oneCount eq "")
	{
		$oneCount = 0;
	}

	return ($zeroCount,$oneCount);
}

sub calMAF
{
	my ($zeroCount,$oneCount,$minorAllele) = @_;

	my $maf = -1;

	if (($zeroCount =~ /^\d+$/)&&($oneCount =~ /^\d+$/))
	{
		my $total = $zeroCount + $oneCount;

		if ($total > 0)
		{
			if ($minorAllele == 0)
			{
				$maf = $zeroCount / $total;
			}
			elsif ($minorAllele == 1)
			{
				$maf = $oneCount / $total;
			}
		}
	}

	return ($maf);
}

sub calMean
{
	my (@arr) = @_;
	
	my $num = int(@arr);
	
	my $mean = 0;
	
	for (my $i = 0; $i < $num; $i++)
	{
		$mean = $mean + $arr[$i];
	}
	
	$mean = $mean / $num;
	
	return ($mean);
}

sub calSD
{
	my ($mean,@arr) = @_;
	
	my $n = int(@arr);
	
	my $sd = 0;
	
	for (my $i = 0; $i < $n; $i++)
	{
		$sd = $sd + ($arr[$i] - $mean) * ($arr[$i] - $mean);
	}
	
	$sd = $sd / ($n - 1);
	
	$sd = sqrt($sd);
	
	return ($sd);
}

1;
