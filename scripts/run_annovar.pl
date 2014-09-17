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

my $vcfFile;
my $gene;
my $phenotypeFile;
my $snpList;
my $flag;	
my $outDIR;

my $optResult=GetOptions(
			'vcfFile=s' => \$vcfFile,
			'gene=s'=> \$gene,
			'phenotypeFile=s' => \$phenotypeFile,
			'snpList=s' => \$snpList,
			'flag=s' => \$flag,
			'outDIR=s' => \$outDIR);

my $usage = <<END;
----------------------------------------------------------------------------------
GeneZoom.pl : 
----------------------------------------------------------------------------------
This tool is a visualization tool that shows the frequency of variants in a 
predefined region for groups of individuals.

Note: 
	The SNPs and VCF should be hg19 version.
	VCF file must be annotated by ANOVAR.

Version : 1.1.0

Report Bug(s) : jich[at]umich[dot]edu
----------------------------------------------------------------------------------
Usage :
	perl GeneZoom.pl --vcfFile vcfFile --gene gene --MAFThreshold 0.01 --phenotypeFile phenotypeFile --snpList snpList --flag splicing,nonsense,missense --outDIR outDIR
	perl GeneZoom.pl --vcfFile vcfFile --gene gene --MAFThreshold 0.01 --phenotypeFile phenotypeFile --flag splicing,nonsense,missense --outDIR outDIR
----------------------------------------------------------------------------------
END

unless (($optResult)&&($vcfFile)&&($gene)&&($phenotypeFile)&&($flag)&&($outDIR))
{
	die "$usage\n";
}

=pod
if ($MAFThreshold !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
{
	print "MAFThreshold should be a number!\n";

	exit(1);
}
=cut

if ($outDIR !~ /\/$/)
{
	$outDIR = $outDIR."/";
}

if (!(-e $outDIR))
{
	my $cmd = system("mkdir --p $outDIR");

	if ($cmd != 0)
	{
		print "can't create the dir $outDIR!\n";

		exit(1);
	}
}

use lib "$Bin/../lib";

use FileAndData;
#use VCF;
#use GeneZoomPlot;
#use BeanPlot;

my $dataObj = new FileAndData;

#my $vcfObj = new VCF;
#my $GeneZoomPlotObj = new GeneZoomPlot;
#my $BeanPlotObj = new BeanPlot;

## action with FileAndData
$dataObj->{"vcfFile"} = $vcfFile;
$dataObj->{"gene"} = $gene;
$dataObj->{"phenotypeFile"} = $phenotypeFile;
if (defined($snpList))
{
	$dataObj->{"SNPList"} = $snpList;
}
$dataObj->{"flagString"} = $flag;
$dataObj->{"outDIR"} = $outDIR;

$dataObj->checkInputs();
$dataObj->cleanFileAndDataObj();
$dataObj->readAndCheckFlags();
$dataObj->readPhenotypeFile();
$dataObj->readGeneInformation();
$dataObj->readSNPList();
$dataObj->readVCF();

use VCF;
my $vcfObj = new VCF;

## action with VCF
$vcfObj->cleanVCFObj();
$vcfObj->{"outDIR"} = $dataObj->{"outDIR"};
$vcfObj->{"targetSNPFile"} = $dataObj->{"outDIR"}."SNPs.on.target.region.list";
$vcfObj->calculateMAF();

=pod
## action with VCF
$vcfObj->{"MAFThreshold"} = $MAFThreshold;

while (my ($k,$v) = each %{$dataObj->{"VCFIDofPhenotypeSample"}})
{
	$vcfObj->{"VCFIDofPhenotypeSample"}{$k} = $v;
}

for (my $i = 0; $i < int(@{$dataObj->{"phenotype"}}); $i++)
{
	my $sample = $dataObj->{"phenotype"}[$i][0];
	my $phenotype = $dataObj->{"phenotype"}[$i][1];
	my $phenotypeValue = $dataObj->{"phenotype"}[$i][3];

	$vcfObj->{"samplePhenotype"}{$sample} = $phenotype;
	$vcfObj->{"samplePhenotypeValue"}{$sample} = $phenotypeValue;
}

for (my $i = 0; $i < int(@{$dataObj->{"targetSNP"}}); $i++)
#for (my $i = 0; $i < 1; $i++)
{
	$vcfObj->cleanVCFObj();
	$vcfObj->{"SNPLine"} = $dataObj->{"targetSNP"}[$i];
	$vcfObj->readAnnotation();
	$vcfObj->findMinorAllel();
	$vcfObj->calculateMAF();

	if ($vcfObj->{"MAF"} =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$vcfObj->classifySNP();
	}

	my $phenotype = "case";
	while (my ($population,$str) = each %{$dataObj->{"casePopulationGroup"}})
	{
		my $thisMAF = $vcfObj->calculateMAFInsubSampleSet($str);

		if ($thisMAF =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
		{
			$vcfObj->addSNPtoCaseControlPopulationGroup($population,$phenotype,$thisMAF);
		}
	}
	
	$phenotype = "control";
	while (my ($population,$str) = each %{$dataObj->{"controlPopulationGroup"}})
	{
		my $thisMAF = $vcfObj->calculateMAFInsubSampleSet($str);

		if ($thisMAF =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
		{
			$vcfObj->addSNPtoCaseControlPopulationGroup($population,$phenotype,$thisMAF);
		}
	}
}

## action with GeneZoomPlot
$GeneZoomPlotObj->cleanGeneZoomPlotObj();
$GeneZoomPlotObj->{"gene"} = $gene;
$GeneZoomPlotObj->{"geneZoomRScript"} = $out.$gene.".GeneZoom.plot.R";
$GeneZoomPlotObj->{"geneZoomPDF"} = $out.$gene.".GeneZoom.plot.pdf";

for (my $i = 0; $i < int(@{$dataObj->{"exonStarts"}}); $i++)
{
	$GeneZoomPlotObj->{"exonStarts"}[$i] = $dataObj->{"exonStarts"}[$i];
}

for (my $i = 0; $i < int(@{$dataObj->{"exonEnds"}}); $i++)
{
	$GeneZoomPlotObj->{"exonEnds"}[$i] = $dataObj->{"exonEnds"}[$i];
}

while (my ($key,$value) = each %{$vcfObj->{"caseGroup"}})
{
	$GeneZoomPlotObj->{"caseGroup"}{$key} = $vcfObj->{"caseGroup"}{$key};
}

while (my ($key,$value) = each %{$vcfObj->{"controlGroup"}})
{
	$GeneZoomPlotObj->{"controlGroup"}{$key} = $vcfObj->{"controlGroup"}{$key};
}

my %populationHash;

while (my ($key,$value) = each %{$vcfObj->{"caseGroup"}})
{
	$populationHash{$key} = 1;
}

while (my ($key,$value) = each %{$vcfObj->{"caseGroup"}})
{
	$populationHash{$key} = 1;
}

my $k = 0;
while (my ($key,$value) = each %populationHash)
{
	$GeneZoomPlotObj->{"population"}[$k] = $key;
	$k = $k + 1;
}

for (my $i = 0; $i < int(@{$dataObj->{"flags"}}); $i++)
{
	$GeneZoomPlotObj->{"flags"}{$dataObj->{"flags"}[$i]} = 1;
}

$GeneZoomPlotObj->matchAnnotationWithColorID();
$GeneZoomPlotObj->createGeneZoomRScript();
$GeneZoomPlotObj->runGeneZoomRScript();

## action with BeanPlot
$BeanPlotObj->{"beanPlotRScript"} = $out.$gene.".BeanPlot.R";
$BeanPlotObj->{"beanPlotPDF"} = $out.$gene.".BeanPlot.pdf";
$BeanPlotObj->{"xlab"} = "x lab";
$BeanPlotObj->{"ylab"} = "y lab";
$BeanPlotObj->{"main"} = $gene." bean plot";

$vcfObj->createBeanPlotGroup();
while (my ($k,$v) = each %{$vcfObj->{"beanPlotGroup"}})
{
	$BeanPlotObj->{"groups"}{$k} = $v;
}

$BeanPlotObj->createBeanPlotRScript();
$BeanPlotObj->runBeanPlotRScript();
=cut

exit(0);
