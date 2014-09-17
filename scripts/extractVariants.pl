#! /usr/bin/perl -w

############################################################################
##
##  CopyRight (c) 2015 Regents of the University of Michigan
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
############################################################################

use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);

my $vcf;
my $gene;
my $out;

GetOptions(
			'vcf=s' => \$vcf,
			'gene=s'=> \$gene,
			'out=s' => \$out);

my $usage = <<END;
---------------------------------------------------------------
extractVariants.pl : 
---------------------------------------------------------------
This tool is to extract SNPs in Gene region from a VCF 

Note: 
	The SNPs and VCF should be hg19 version.

Version : 1.0.0

Report Bug(s) : jich[at]umich[dot]edu
---------------------------------------------------------------
Usage :
	perl extractVariants.pl --vcf vcf --gene gene --out out
---------------------------------------------------------------
END

unless (($vcf)&&($gene)&&($out))
{
	die "$usage\n";
}

require "$Bin/../lib/functions.pl";

## read Gene region
my $refGene = "$Bin/../ref/refGene.clean.txt";

open (IN,$refGene) || die "can't open the file:$refGene!\n";

my $readline;

my $geneChr = -1;
my $geneStart = -1;
my $geneEnd = -1;

while (defined($readline=<IN>))
{
	chomp $readline;

	my @fields = split(/\t/,$readline);
	my $thisChr = $fields[2];
	my $thisStart = $fields[4];
	my $thisEnd = $fields[5];
	my $thisGeneName = $fields[12];

	$thisChr =~ s/^chr//i;

	if ($gene eq $thisGeneName)
	{
		if (($thisChr =~ /^\d+$/)||($thisChr =~ /^x$/i)||($thisChr =~ /^y$/i)) 
		{
			$geneChr = $thisChr;
			$geneStart = $thisStart;
			$geneEnd = $thisEnd;

			last;
		}
	}
}

close IN;

if (($geneChr == -1)||($geneStart == -1)||($geneEnd == -1))
{
	print "can't find the gene region for $gene!\n";

	exit(1);
}

if ($geneChr =~ /^x$/i)
{
	$geneChr = 23;
}

if ($geneChr =~ /^y$/i)
{
	$geneChr = 24;
}

## extract variants in gene region
my $vcfType = getFileType($vcf);

if ($vcfType eq "gzip")
{
	open(IN, "gunzip -c $vcf |") || die "can't open the file:$vcf!\n";
}
elsif ($vcfType eq "ASCII")
{
	open (IN,$vcf) || die "can't open the file:$vcf!\n";
}
else
{
	print "vcf($vcf has the wrong file format! It should be ASCII or gz file!\n)";

	exit(1);
}

open (OUT,"| gzip > ".$out) || die "can't write to the file:$out!\n";

while (defined($readline=<IN>))
{
	if ($readline =~ /^\#/)
	{
		print OUT $readline;
	}
	else
	{
		my @fields = split(/\t/,$readline);

		my $chr = $fields[0];
		my $pos = $fields[1];
		my $filter = $fields[6];

		$chr =~ s/^chr//i;

		if ($chr =~ /^x$/i)
		{
			$chr = 23;
		}
		elsif ($chr =~ /^y$/i)
		{
			$chr = 24;
		}

		if ($filter =~ /^pass$/i)
		{
			if ($chr == $geneChr)
			{
				if (($geneStart <= $pos)&&($pos <= $geneEnd))
				{
					print OUT $readline;
				}
			}
		}
	}
}

close IN;
close OUT;

exit(0);
