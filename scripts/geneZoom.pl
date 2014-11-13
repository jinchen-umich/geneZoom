#! /usr/bin/perl -w
############################################################################
##
## Name: geneZoom
##
## Description:
##   This tool is a visualization tool that shows the frequency of variants in a
## predefined region for groups of individuals.
##
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
use Switch;
use Pod::Usage;
use Getopt::Long;
use FindBin qw($Bin);

require "$Bin/../lib/functions.pl";
require "$Bin/../lib/vcf.pl";

my $vcf;
my $gene;
my $phenotypeFile;
my $sampleFieldName;
my $phenotypeFieldName;
my $phenotypeDelim;
my $snpList;
my $snpChrFieldName;
my $snpPosFieldName;
my $snpChrPosFieldName;
my $snpDelim;
my $lableSNPs;
my $flags;
my $defaultIntron;
my $title;
my $xlab;
my $ylab;
my $titleCex;
my $xlabCex;
my $ylabCex;
my $scatterYAxisCex;
my $phenotyeMeanLineColor;
my $phenotyeMeanLineType;
my $phenotyeSDLineColor;
my $phenotyeSDLineType;
my $exonRegionColor;
my $beanPlotXAxisLabelAngle;
my $beanPlotXAxisLableCex;
my $beanPlotXAxisLablePos1;
my $beanPlotXAxisLablePos2;
my $width;
my $height;
my $format;
my $outDIR;

my $version = "1.0.1";

my $usage = <<END;
-------------
GeneZoom.pl : 
-------------
This tool is a visualization tool that shows the frequency of variants in a predefined region for groups of individuals.

Note: 
  The SNPs and VCF should be hg19 version.
  VCF file must have the header greater than 4.0 version.
  This tool will run ANOVAR to annotate VCF. The annotation values should be in the value list of ANOVAR(http://www.openbioinformatics.org/annovar/annovar_gene.html).

Version : 1.0.1

Report Bug(s) : jich[at]umich[dot]edu
-------------------------------------
Usage :
  perl GeneZoom.pl --vcf vcf --phenotypeFile phenotypeFile --sampleFieldName sample --phenotypeFieldName phenotype --phenotypeDelim tab/comma/blank --snpList snpList --flag "splicing:0.01:0.02,nonsense:blue,missense" --format pdf --outDIR outDIR

  perl GeneZoom.pl --vcf vcf --phenotypeFile phenotypeFile --sampleFieldName sample --phenotypeFieldName phenotype --phenotypeDelim tab/comma/blank --snpList snpList --snpChrFieldName chr --snpPosFieldName pos --snpDelim tab/comma/blank --flag "splicing:green,nonsense:0.02:0.03,missense" --lables "chr1:123,chr2:234" --outDIR outDIR
--------------------------------------
END

if (int (@ARGV) == 0)
{
	die "$usage\n";
}

for (my $i = 0; $i < int(@ARGV); $i++)
{
	my $fcn = $ARGV[$i];

	if ($fcn =~ /^([\-])*help$/) {
		pod2usage(-exitval => 2);
	}
	if (! $fcn) {
		warn "ERROR: Missing command. Please see the usage below.\n";
				pod2usage(-exitval => 2);
	}
	if ($fcn =~ /^([\-])*man$/) {
				pod2usage(-verbose => 2,  -exitval => 2);
	}

	if ($fcn =~ /^([\-])*version$/)
	{
		print "GeneZoom : $version\n";

		exit(0);
	}
}

GetOptions(
			'vcf=s'											=> \$vcf,
			'gene=s'										=> \$gene,
			'phenotypeFile=s'						=> \$phenotypeFile,
			'sampleFieldName=s'					=> \$sampleFieldName,
			'phenotypeFieldName=s'			=> \$phenotypeFieldName,
			'phenotypeDelim=s'					=> \$phenotypeDelim,
			'snpList=s'									=> \$snpList,
			'snpChrFieldName=s'					=> \$snpChrFieldName,
			'snpPosFieldName=s'					=> \$snpPosFieldName,
			'snpChrPosFieldName=s'			=> \$snpChrPosFieldName,
			'snpDelim=s'								=> \$snpDelim,
			'lableSNPs=s'								=> \$lableSNPs,
			'flags=s'										=> \$flags,
			'defaultIntron=f'						=> \$defaultIntron,
			'title=s'										=> \$title,
			'xlab=s'										=> \$xlab,
			'ylab=s'										=> \$ylab,
			'titleCex=f'								=> \$titleCex,
			'xlabCex=f'									=> \$xlabCex,
			'ylabCex=f'									=> \$ylabCex,
			'scatterYAxisCex=f'					=> \$scatterYAxisCex,
			'phenotyeMeanLineColor=s'		=> \$phenotyeMeanLineColor,
			'phenotyeMeanLineType=s'		=> \$phenotyeMeanLineType,
			'phenotyeSDLineColor=s'			=> \$phenotyeSDLineColor,
			'phenotyeSDLineType=s'			=> \$phenotyeSDLineType,
			'exonRegionColor=s'					=> \$exonRegionColor,
			'beanPlotXAxisLabelAngle=f'	=> \$beanPlotXAxisLabelAngle,
			'beanPlotXAxisLableCex=f'		=> \$beanPlotXAxisLableCex,
			'beanPlotXAxisLablePos1=f'	=> \$beanPlotXAxisLablePos1,
			'beanPlotXAxisLablePos2=f'	=> \$beanPlotXAxisLablePos2,
			'width=f'										=> \$width,
			'height=f'									=> \$height,
			'format=s'									=> \$format,
			'outDIR=s'									=> \$outDIR);


my $annotations				= "NA";
my $annotationColors	= "NA";
my $beanPlotNum				=	0;

my $msg = "NA";

##############################################################
# Create output directory and log file
##############################################################
my ($sec,$min,$hour,$day,$mon,$year,$weekday,$yeardate,$savinglightday) = getDateAndTime();

my $timestamp = $year.$mon.$day."_".$gene;

if (!(defined($outDIR)))
{
	print "Error : Please define outDIR which is the result directory!\n";

	exit(1);
}

if ($outDIR !~ /\/$/)
{
	$outDIR = $outDIR."/";
}

$outDIR = $outDIR.$timestamp."/";

if (-e $outDIR)
{
	my $cmd = system("rm -rf $outDIR");

	if ($cmd != 0)
	{
		print "Error : can't remove the dir $outDIR!\n";

		exit(1);
	}
	else
	{
		$cmd = system("mkdir --p $outDIR");

		if ($cmd != 0)
		{
			print "Error : can't create the dir $outDIR!\n";

			exit(1);
		}
	}
}

my $cmd = system("mkdir --p $outDIR");

if ($cmd != 0)
{
	print "Error : can't create the dir $outDIR!\n";

	exit(1);
}

my $log = $outDIR."geneZoom.$gene.log";

$msg = "Result directory($outDIR) is created!";

logFile($log,$msg);

##############################################################
# Check all parameters
##############################################################
if (!(defined($vcf)))
{
	$msg = "Please define VCF file!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $vcf)
{
	$msg = "VCF is defined to $vcf!";

	logFile($log,$msg);
}
else
{
	$msg = "VCF ($vcf) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (!(defined($gene)))
{
	$msg = "Please define Gene Name!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}
else
{
	$msg = "Gene is defined to $gene!";

	logFile($log,$msg);
}

if (!(defined($phenotypeFile)))
{
	$msg = "Please define phenotype file!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $phenotypeFile)
{
	$msg = "The phenotype is defined to $phenotypeFile!";

	logFile($log,$msg);
}
else
{
	$msg = "The phenotype file ($phenotypeFile) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (!(defined($sampleFieldName)))
{
	$msg = "Please define sample field name in phenotype file!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}
else
{
	$msg = "sample field in phenotype file is defined to $sampleFieldName!";

	logFile($log,$msg);
}

if (!(defined($phenotypeFieldName)))
{
	$msg = "Please define phenotype field name in phenotype file!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}
else
{
	$msg = "Phenotype field in phenotype file is defined to $phenotypeFieldName!";

	logFile($log,$msg);
}

if (!(defined($phenotypeDelim)))
{
	$msg = "Please define phenotype delim!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (($phenotypeDelim !~ /^tab$/i)&&($phenotypeDelim !~ /^comma$/i)&&($phenotypeDelim !~ /^blank$/i))
{
	$msg = "phenotypeDelim should be defined to tab,comma or blank!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}
else
{
	$msg = "The delim in phenotype file is $phenotypeDelim!";

	logFile($log,$msg);
}

if (defined($snpList))
{
	if (!(-e $snpList))
	{
		$msg = "snpList($snpList) doesn't exist!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
	else
	{
		$msg = "The SNP list is defined to $snpList";

		logFile($log,$msg);

		if (!(defined($snpDelim)))
		{
			$msg = "Please define SNP delim!";
			$msg = createErrMsg($msg);

			popErr($log,$msg);
		}
		else
		{
			if (($snpDelim !~ /^tab$/i)&&($snpDelim !~ /^comma$/i)&&($snpDelim !~ /^blank$/i))
			{
				$msg = "snpDelim should be defined to tab,comma or blank!";
				$msg = createErrMsg($msg);

				popErr($log,$msg);
			}
			else
			{
				$msg = "The delim of SNP list is defined to $snpDelim!";

				logFile($log,$msg);
			}
		}

		unless((($snpChrFieldName)&&($snpPosFieldName))||($snpChrPosFieldName))
		{
			$msg = "Please define snpChrFieldName and snpPosFieldName, or define snpChrPosFieldName!";
			$msg = createErrMsg($msg);

			popErr($log,$msg);
		}
		
		if ((($snpChrFieldName)||($snpPosFieldName))&&($snpChrPosFieldName))
		{
			$msg = "Please define snpChrFieldName and snpPosFieldName, or define snpChrPosFieldName!";
			$msg = createErrMsg($msg);

			popErr($log,$msg);
		}

		if ((defined($snpChrFieldName))&&($snpPosFieldName))
		{
			$msg = "The CHR field in SNP list is defined to $snpChrFieldName!";

			logFile($log,$msg);

			$msg = "The POS field in SNP list is defined to $snpPosFieldName!";

			logFile($log,$msg);
		}

		if (defined($snpChrPosFieldName))
		{
			$msg = "The CHR:POS field in SNP list is defined to $snpChrPosFieldName!";

			logFile($log,$msg);
		}
	}
}

if (defined($lableSNPs))
{
	$msg = "The lable SNPs are defined to $lableSNPs!";

	logFile($log,$msg);
}
else
{
	$msg = "Not defined lable SNPs. It is NULL!";

	logFile($log,$msg);
}

if (!(defined($flags)))
{
	$flags = "missense,stoploss,stopgain,splicing";

	$msg = "User dones't define flags. Use the default : $flags!";

	logFile($log,$msg);
}
else
{
	$msg = "The flags is defined to $flags";

	logFile($log,$msg);
}

if (!(defined($defaultIntron)))
{
	$defaultIntron = 500;

	$msg = "The intron length is defined to default : 500!";

	logFile($log,$msg);
}
else
{
	if ($defaultIntron !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "The default intron should be a number!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
	else
	{
		$msg = "The intron length is defined to $defaultIntron!";

		logFile($log,$msg);
	}
}

if (!(defined($title)))
{
	$title = $gene." variants identified";
}

$msg = "The title of plot is defined to $title!";

logFile($log,$msg);

if (!(defined($xlab)))
{
	$xlab = $gene." exons";
}

$msg = "The xlab of plot is defined to $xlab!";

logFile($log,$msg);

if (!(defined($ylab)))
{
	$ylab = "Phenotype";
}

$msg = "The ylab of plot is defined to $ylab!";

logFile($log,$msg);

if (!(defined($titleCex)))
{
	$titleCex = 1;
}
else
{
	if ($titleCex !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "titleCex($titleCex) should be a number!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The cex of title is defined to $titleCex!";

logFile($log,$msg);

if (!(defined($xlabCex)))
{
	$xlabCex = 1;
}
else
{
	if ($xlabCex !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "xlabCex($xlabCex) should be a number!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The cex of xlab is defined to $xlabCex!";

logFile($log,$msg);

if (!(defined($ylabCex)))
{
	$ylabCex = 1;
}
else
{
	if ($ylabCex !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "ylabCex($ylabCex) should be a number!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The cex of ylab is defined to $ylabCex!";

logFile($log,$msg);

if (!(defined($scatterYAxisCex)))
{
	$scatterYAxisCex = 1;
}
else
{
	if ($scatterYAxisCex !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "scatterYAxisCex($scatterYAxisCex) should be a number!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The cex of scatter plot y axis is defined to $scatterYAxisCex!";

logFile($log,$msg);

my %colorHash;
undef %colorHash;

$msg = &readColorList(\$Bin,\%colorHash);

popErr($log,$msg);

if (!(defined($phenotyeMeanLineColor)))
{
	$phenotyeMeanLineColor = "blue";
}
else
{
	$msg = &checkColor(\$phenotyeMeanLineColor,\%colorHash);

	popErr($log,$msg);
}

$msg = "The color of phenotype mean line is defined to $phenotyeMeanLineColor!";

logFile($log,$msg);

my %lineTypeHash;
undef %lineTypeHash;

$msg = &readLineTypeList(\$Bin,\%lineTypeHash);

popErr($log,$msg);

if (!(defined($phenotyeMeanLineType)))
{
	$phenotyeMeanLineType = "solid";
}
else
{
	$msg = &checkLineType(\$phenotyeMeanLineType,\%lineTypeHash);

	popErr($log,$msg);
}

$msg = "The line type of phenotype mean line is defined to $phenotyeMeanLineType!";

logFile($log,$msg);
												 
if (!(defined($phenotyeSDLineColor)))
{
	$phenotyeSDLineColor = "blue";
}
else
{
	$msg = &checkColor(\$phenotyeSDLineColor,\%colorHash);

	popErr($log,$msg);
}

$msg = "The color of phenotype SD line is defined to $phenotyeSDLineColor!";

logFile($log,$msg);

if (!(defined($phenotyeSDLineType)))
{
	$phenotyeSDLineType = "dashed";
}
else
{
	$msg = &checkLineType(\$phenotyeSDLineType,\%lineTypeHash);

	popErr($log,$msg);
}

$msg = "The line type of phenotype SD line is defined to $phenotyeSDLineType!";

logFile($log,$msg);

if (!(defined($exonRegionColor)))
{
	$exonRegionColor = "blue";
}
else
{
	$msg = &checkColor(\$exonRegionColor,\%colorHash);

	popErr($log,$msg);
}

#my $beanPlotXAxisLabelAngle; Not use now, for next version

if (!(defined($beanPlotXAxisLabelAngle)))
{
	$beanPlotXAxisLabelAngle = 45;
}
else
{
	if ($beanPlotXAxisLabelAngle !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "beanPlotXAxisLabelAngle($beanPlotXAxisLabelAngle) should be a number!\n";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The label angle of beanplot x axis is defined to $beanPlotXAxisLabelAngle!";

logFile($log,$msg);

if (!(defined($beanPlotXAxisLableCex)))
{
	$beanPlotXAxisLableCex = 1;
}
else
{
	if ($beanPlotXAxisLableCex !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "beanPlotXAxisLableCex($beanPlotXAxisLableCex) should be a number!\n";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The cex of beanplot x axis label is defined to $beanPlotXAxisLableCex!";

logFile($log,$msg);
															 
if (!(defined($beanPlotXAxisLablePos1)))
{
	$beanPlotXAxisLablePos1 = 0.5;
}
else
{
	if ($beanPlotXAxisLablePos1 !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "beanPlotXAxisLablePos1($beanPlotXAxisLablePos1) should be a number!\n";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The position 1 of beanplot x axis label is defined to $beanPlotXAxisLablePos1!";

logFile($log,$msg);

if (!(defined($beanPlotXAxisLablePos2)))
{
	$beanPlotXAxisLablePos2 = 1.5;
}
else
{
	if ($beanPlotXAxisLablePos2 !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "beanPlotXAxisLablePos2($beanPlotXAxisLablePos2) should be a number!\n";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The position 2 of beanplot x axis label is defined to $beanPlotXAxisLablePos2!";

logFile($log,$msg);
																 
if (!(defined($width)))
{
	$width = 14.1;
}
else
{
	if ($width !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "width($width) should be a number!\n";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The width of plot is defined to $width!";

logFile($log,$msg);
																  
if (!(defined($height)))
{
	$height = 10;
}
else
{
	if ($height !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	{
		$msg = "height($height) should be a number!\n";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The height of plot is defined to $height!";

logFile($log,$msg);
																	 
if (!(defined($format)))
{
	$format = "pdf";
}
else
{
	if (($format !~ /^pdf$/i)&&($format !~ /^tiff$/i)&&($format !~ /^png$/i))
  {
		$msg = "The format of output file should be PDF, TIFF or PNG!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}
}

$msg = "The format of plot is defined to $format!";

logFile($log,$msg);

$msg = "All parameters are verified!";

logFile($log,$msg);


##############################################################
# Check phenotype file
##############################################################
$msg = verifyPhenotypeFile($phenotypeFile,$sampleFieldName,$phenotypeFieldName,$phenotypeDelim);

popErr($log,$msg);

$msg = "The phenotype file is checked!";

logFile($log,$msg);



##############################################################
# Check SNP List
##############################################################
if (defined($snpList))
{
	if (!(defined($snpChrFieldName)))
	{
		$snpChrFieldName = "NA";
	}

	if (!(defined($snpPosFieldName)))
	{
		$snpPosFieldName = "NA";
	}

	if (!(defined($snpChrPosFieldName)))
	{
		$snpChrPosFieldName = "NA";
	}

	$msg = verifySNPListFile($snpList,$snpChrFieldName,$snpPosFieldName,$snpChrPosFieldName,$snpDelim);

	popErr($log,$msg);

	$msg = "The SNP list is checked!";
	
	logFile($log,$msg);
}



##############################################################
## get gene region
##############################################################

my $refGene = "$Bin/../ref/refGene.clean.txt";

if (!(-e $refGene))
{
	$msg = "Error : Can't find the reference file ($refGene)!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

my $geneChr = "NA";
my $geneStart = "NA";
my $geneEnd = "NA";
my $exonStarts = "NA";
my $exonEnds = "NA";

($msg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds) = getGeneRegion($refGene,$gene);

popErr($log,$msg);

my $newExonStarts = "NA";
my $newExonEnds = "NA";

($msg,$newExonStarts,$newExonEnds) = transformGeneRegion($geneStart,$geneEnd,$exonStarts,$exonEnds,$defaultIntron);

popErr($log,$msg);

## output gene region
my $geneRegionFile = $outDIR."geneZoom.$gene.region.txt";

open (OUT,">".$geneRegionFile) || die "can't write to the file:$geneRegionFile!\n";

print OUT "geneName\tgeneChr\tgeneStart\tgeneEnd\texonStarts\texonEnds\tnewExonStarts\tnewExonEnds\n";
print OUT "$gene\t$geneChr\t$geneStart\t$geneEnd\t$exonStarts\t$exonEnds\t$newExonStarts\t$newExonEnds\n";

close OUT;

$msg = "Gene($gene) region is found!\nGene($gene) is on CHR$geneChr!\nGene($gene) starts from $geneStart!\nGene($gene) ends to $geneEnd!\nThe exon starts are $exonStarts.\nThe exon ends are $exonEnds.";

logFile($log,$msg);



##############################################################
## read flags to flagHash;
##############################################################

my %flagHash;
undef %flagHash;

($msg,$annotations,$annotationColors,%flagHash) = readAnnotationFlags($flags,%colorHash);

popErr($log,$msg);

## output annotation flags
my $annotationFlagFile = $outDIR."geneZoom.annotation.flag.txt";

open (OUT,">".$annotationFlagFile) || die "can't write to the file:$annotationFlagFile!\n";

print OUT "annotation\tstart\tend\tcolor\n";

while (my ($anno,$value) = each %flagHash)
{
	print OUT "$anno\t$value\n";
}

close OUT;

$msg = "Flags($flags) has been read!";

logFile($log,$msg);


##############################################################
## read snp list
##############################################################

my %snpHash;
undef %snpHash;

if (defined($snpList))
{
	$msg = &readSNPList(\$snpList,\$snpChrFieldName,\$snpPosFieldName,\$snpChrPosFieldName,\$snpDelim,\%snpHash);

	popErr($log,$msg);

## output SNP list
	my $snpFile = $outDIR."geneZoom.$gene.snp.list.txt";

	open (OUT,">".$snpFile) || die "can't write to the file:$snpFile!\n";

	print OUT "chr:pos\n";

	while (my ($k,$v) = each %snpHash)
	{
		print OUT "$k\n";
	}

	close OUT;

	$msg = "SNP list($snpList) has been read!";
	 
	logFile($log,$msg);
}



##############################################################
## run ANNOVAR for VCF
##############################################################

my %annoHash;
undef %annoHash;

$msg = &runANNOVARForVCF(\$vcf,\$outDIR,\$Bin,\%annoHash);

popErr($log,$msg);

## clean annotation results with SNP list
if (defined($snpList))
{
	while (my ($snp,$anno) = each %annoHash)
	{
		if (!(exists($snpHash{$snp})))
		{
			delete ($annoHash{$snp});
		}
	}
}

## output annotation file
my $annotationSNPList = $outDIR."geneZoom.$gene.annotation.SNP.list.txt";

open (OUT,">".$annotationSNPList) || die "can't write to the file:$annotationSNPList!\n";

print OUT "chr\tpos\tannotation\n";

while (my ($snp,$anno) = each %annoHash)
{
	$snp =~ s/\:/\t/;

	print OUT "$snp\t$anno\n";
}

close OUT;

$msg = "SNPs have been annotated with ANNOVAR! The annotated SNPs are saved to the file : $annotationSNPList!";

logFile($log,$msg);


##############################################################
## read phenotype file
##############################################################

my %phenotypeHash;
undef %phenotypeHash;

$msg = &readPhenotypeFile(\$vcf,\$phenotypeFile,\$sampleFieldName,\$phenotypeFieldName,\$phenotypeDelim,\%phenotypeHash);

popErr($log,$msg);

## output phenotype file
my $cleanedphenotypeFile = $outDIR."geneZoom.$gene.phenotype.txt";

open (OUT,">".$cleanedphenotypeFile) || die "can't write to the file:$cleanedphenotypeFile!\n";

print OUT "sample\tphenotype\n";

while (my ($sample,$pheno) = each %phenotypeHash)
{
	print OUT "$sample\t$pheno\n";
}

close OUT;

$msg = "SNPs' phenotype values have been read and saved to the file : $cleanedphenotypeFile!";

logFile($log,$msg);




##############################################################
## calculate minor allel and MAF
##############################################################
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
	$msg = "Error : vcf($vcf) has the wrong file format! It should be ASCII or gz file!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

my $scatterPlotData = $outDIR."geneZoom.$gene.scatter.plot.data.txt";
my $allPlotData = $outDIR."geneZoom.$gene.all.plot.data.txt";
my $otherPlotData = $outDIR."geneZoom.$gene.other.plot.data.txt";

open (SCATTER,">".$scatterPlotData) || die "can't write to the file:$scatterPlotData!\n";
open (ALL,">".$allPlotData) || die "can't write to the file:$allPlotData!\n";
open (OTHER,">".$otherPlotData) || die "can't write to the file:$otherPlotData!\n";

print SCATTER "chr\tpos\tannotation\tcolor\tphenotype\tmaf\tgenotype\tminorAllele\n";
print ALL "chr\tpos\tannotation\tcolor\tphenotype\tmaf\tgenotype\tminorAllele\n";
print OTHER "chr\tpos\tannotation\tcolor\tphenotype\tmaf\tgenotype\tminorAllele\n";

my @sampleArr;
undef @sampleArr;

my $readline;

while (defined($readline=<IN>))
{
	if ($readline =~ /^\#\#/)
	{
		# do nothing
	}
	elsif ($readline =~ /^\#CHROM/)
	{
		chomp $readline;

		@sampleArr = split(/\t/,$readline);
	}
	else
	{
		chomp $readline;

		my @fields = split(/\t/,$readline);

		my $chr = $fields[0];
		$chr =~ s/^chr//i;

		if ($chr =~ /^x$/i)
		{
			$chr = 23;
		}
		elsif ($chr =~ /^y$/i)
		{
			$chr = 24;
		}

		my $pos = $fields[1];

		my $snp = $chr.":".$pos;

		my ($zeroCount,$oneCount,$minorAllele) = &calculateMinorAllele(\@fields);

		my $maf = calMAF($zeroCount,$oneCount,$minorAllele);

		if ($maf > 0)
		{
			if (($minorAllele == 0)||($minorAllele == 1))
			{
				if (exists($annoHash{$snp}))
				{
					my $anno = $annoHash{$snp};

					my ($plotThisSNP,$thisColor) = &fallInGroup(\%flagHash,\$anno,\$maf);

					if ($plotThisSNP eq "true")
					{
						for (my $i = 9; $i < int(@fields); $i++)
						{
							my $isMinorAllele = hasMinorAllele($fields[$i],$minorAllele);

							if ($isMinorAllele eq "true")
							{
								if (exists($phenotypeHash{$sampleArr[$i]}))
								{
									print SCATTER "$chr\t$pos\t$anno\t$thisColor\t$phenotypeHash{$sampleArr[$i]}\t$maf\t$fields[$i]\t$minorAllele\n";
									print ALL "$chr\t$pos\t$anno\tNoColor\t$phenotypeHash{$sampleArr[$i]}\t$maf\t$fields[$i]\t$minorAllele\n";
								}
							}
							else
							{
								if (exists($phenotypeHash{$sampleArr[$i]}))
								{
									print ALL "$chr\t$pos\t$anno\tNoColor\t$phenotypeHash{$sampleArr[$i]}\t$maf\t$fields[$i]\t$minorAllele\n";
									print OTHER "$chr\t$pos\t$anno\tNoColor\t$phenotypeHash{$sampleArr[$i]}\t$maf\t$fields[$i]\t$minorAllele\n";
								}
							}
						}
					}
					else
					{
						for (my $i = 9; $i < int(@fields); $i++)
						{
							if (exists($phenotypeHash{$sampleArr[$i]}))
							{
								print ALL "$chr\t$pos\t$anno\tNoColor\t$phenotypeHash{$sampleArr[$i]}\t$maf\t$fields[$i]\t$minorAllele\n";
								print OTHER "$chr\t$pos\t$anno\tNoColor\t$phenotypeHash{$sampleArr[$i]}\t$maf\t$fields[$i]\t$minorAllele\n";
							}
						}
					}
				}
			}
		}
	}
}

close IN;
close SCATTER;
close ALL;
close OTHER;

$msg = "SNPs' MAFs have been calculated and saved to the file :\n$scatterPlotData\n$otherPlotData\n$allPlotData !";

logFile($log,$msg);




##############################################################
## re-create $annotations and $annotationColors
##############################################################
($msg,$annotations,$annotationColors,$beanPlotNum) = recreateAnnotationAndColorStr($scatterPlotData,$annotations,$annotationColors);

popErr($log,$msg);

$msg = "annotations($annotations) and annotationColors($annotationColors) are re-created!\nbeanPlotNum is defined to $beanPlotNum!";
 
logFile($log,$msg);





##############################################################
## re-calculate SNPs' positions
##############################################################

open (IN,$scatterPlotData) || die "can't open the file:$scatterPlotData!\n";

$readline = <IN>;

my %newPosHash;
undef %newPosHash;
my %posOnNewRegionHash;
undef %posOnNewRegionHash;

while (defined($readline=<IN>))
{
	chomp $readline;

	my @fields = split(/\t/,$readline);

	my $pos = $fields[1];

	if (($geneStart <= $pos)&&($pos <= $geneEnd))
	{
		$newPosHash{$pos} = "NA";
		$posOnNewRegionHash{$pos} = "NA";
	}
}

close IN;

my @regions;
undef @regions;

&transformSNPPos(\%newPosHash,\%posOnNewRegionHash,\$geneStart,\$geneEnd,\$exonStarts,\$exonEnds,\$newExonStarts,\$newExonEnds,\@regions);

my $coordinateTransformationScatterPlotData = $outDIR."geneZoom.$gene.coordinate.transformation.scatter.plot.data.txt";

open (IN,$scatterPlotData) || die "can't open the file:$scatterPlotData!\n";
open (OUT,">".$coordinateTransformationScatterPlotData) || die "can't write to the file:$coordinateTransformationScatterPlotData!\n";

$readline = <IN>;

print OUT "chr\tpos\tnew_pos\tpos_on_region\tannotation\tcolor\tphenotype\n";

while (defined($readline=<IN>))
{
	chomp $readline;

	my @fields = split(/\t/,$readline);
	my $chr = $fields[0];
	my $pos = $fields[1];
	my $anno = $fields[2];
	my $color = $fields[3];
	my $phenotype = $fields[4];

	if ((exists($newPosHash{$pos}))&&(exists($posOnNewRegionHash{$pos})))
	{
		
		print OUT "$chr\t$pos\t$newPosHash{$pos}\t$posOnNewRegionHash{$pos}\t$anno\t$color\t$phenotype\n";
	}
	else
	{
		$msg = "Error : one pos($pos) can't be transformed to new coordinate!";
		$msg = createErrMsg($msg);
		
		last;
	}
}
		
close IN;
close OUT;

popErr($log,$msg);

$msg = "SNPs' positions are re-calculated and saved to the file : $coordinateTransformationScatterPlotData!";

logFile($log,$msg);



##############################################################
## output SNP and exon region match lines
##############################################################

my $matchedLines = $outDIR."geneZoom.$gene.matched.lines.plot.data.txt";

open (OUT,">".$matchedLines) || die "can't write to the file:$matchedLines!\n";

for (my $i = 0; $i < int(@regions); $i++)
{
	print OUT "$regions[$i][0]\t$regions[$i][1]\t$regions[$i][2]\t$regions[$i][3]\t$regions[$i][4]\n";
}

close OUT;

$msg = "The matched lines of SNPs and exon regions are calculated and saved to the file : $matchedLines!";

logFile($log,$msg);





##############################################################
## read lable SNPs
##############################################################
my %lableSNPHash;
undef %lableSNPHash;

if (defined($lableSNPs))
{
	my @fields = split(/\,/,$lableSNPs);

	for (my $i = 0; $i < int(@fields); $i++)
	{
		my @tmp = split(/\:/,$fields[$i]);

		my $chr = $tmp[0];
		my $pos = $tmp[1];

		$chr =~ s/^chr//i;

		if ($chr =~ /^x$/i)
		{
			$chr = 23;
		}

		if ($chr =~ /^y$/i)
		{
			$chr = 24;
		}

		if (($chr =~ /^\d+$/)&&($pos =~ /^\d+$/))
		{
			if ((0 < $chr)&&($chr < 25))
			{
				if ($chr == $geneChr)
				{
					if (($geneStart <= $pos)&&($pos <= $geneEnd))
					{
						my $snp = $chr.":".$pos;

						$lableSNPHash{$snp} = "NA";
					}
					else
					{
						$msg = "One lable snp(chr$chr:$pos) is not in gene($gene) region! Remove it from label SNP list!";

						logFile($log,$msg);
					}
				}
				else
				{
					$msg = "One lable snp(chr$chr:$pos) is not in gene($gene) region! Remove it from label SNP list!";

					logFile($log,$msg);
				}
			}
			else
			{
				$msg = "One lable snp(chr$chr:$pos) is not a SNP! The label SNP should be in format chr:pos!";
				$msg = createErrMsg($msg);

				last;
			}
		}
		else
		{
			$msg = "One lable snp(chr$chr:$pos) is not a SNP! The label SNP should be in format chr:pos!";
			$msg = createErrMsg($msg);

			last;
		}
	}

	popErr($log,$msg);

	my $numofLableSNPs = keys %lableSNPHash;

	if ($numofLableSNPs == 0)
	{
		$msg = "No any lable SNP($lableSNPs) is in gene region($gene,$geneChr,$geneStart,$geneEnd)!";
		$msg = createErrMsg($msg);

		popErr($log,$msg);
	}

	## Find the overlap of label SNPs and scatter SNPs and output them
	open (IN,$coordinateTransformationScatterPlotData) || die "can't open the file:$coordinateTransformationScatterPlotData!\n";
	
	$readline = <IN>;

	my $labelSNPFileHeader = $readline;

	my $validLabelSNPNum = 0;

	while (defined($readline=<IN>))
	{
		chomp $readline;

		my @fields = split(/\t/,$readline);

		my $chr = $fields[0];
		my $pos = $fields[1];

		$chr =~ s/^chr//i;

		if ($chr =~ /^x$/i)
		{
			$chr = 23;
		}

		if ($chr =~ /^y$/i)
		{
			$chr = 24;
		}

		my $thisSNP = $chr.":".$pos;

		if (exists($lableSNPHash{$thisSNP}))
		{
			if ($lableSNPHash{$thisSNP} eq "NA")
			{
				$lableSNPHash{$thisSNP} = $readline;

				$validLabelSNPNum = $validLabelSNPNum + 1;
			}
		}
	}

	close IN;

	if ($validLabelSNPNum == 0)
	{
		$msg = "No any label SMPs($lableSNPs) have valid MAF, phenotype values!";

		logFile($log,$msg);
	}
	else
	{
		my $labelSNPFile = $outDIR."geneZoom.$gene.label.snp.txt";
		
		open (OUT,">".$labelSNPFile) || die "can't write to the file:$labelSNPFile!\n";

		print OUT $labelSNPFileHeader;

		while (my ($s,$v) = each %lableSNPHash)
		{
			if ($v ne "NA")
			{
				print OUT "$v\n";
			}
			else
			{
				$msg = "One label SNP($s) can't be find valid MAF or phenotype value. It is removed!";

				logFile($log,$msg);
			}
		}

		close OUT;

		$msg = "The label SNPs are saved to the file : $labelSNPFile!";

		logFile($log,$msg);
	}
}


##############################################################
## create R script command line
##############################################################
my $RscriptCMDDIR = $Bin;

if ($RscriptCMDDIR !~ /\/$/)
{
	$RscriptCMDDIR = $RscriptCMDDIR."/";
}

my $RscriptsCMD = "Rscript";

my $Rscript = $RscriptCMDDIR."geneZoom.R";

if (-e $Rscript)
{
	$RscriptsCMD = $RscriptsCMD." ".$Rscript;
}
else
{
	$msg = "Rscript($Rscript) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $geneRegionFile)
{
	$RscriptsCMD = $RscriptsCMD." geneRegionFile=\"".$geneRegionFile."\"";
}
else
{
	$msg = "geneRegionFile($geneRegionFile) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $annotationFlagFile)
{
	$RscriptsCMD = $RscriptsCMD." annotationFlag=\"".$annotationFlagFile."\"";
}
else
{
	$msg = "annotationFlagFile($annotationFlagFile) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $coordinateTransformationScatterPlotData)
{
	$RscriptsCMD = $RscriptsCMD."  scatterData=\"".$coordinateTransformationScatterPlotData."\"";
}
else
{
	$msg = "scatterData($coordinateTransformationScatterPlotData) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $allPlotData)
{
	$RscriptsCMD = $RscriptsCMD."  allData=\"".$allPlotData."\"";
}
else
{
	$msg = "allData($allPlotData) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $otherPlotData)
{
	$RscriptsCMD = $RscriptsCMD."  otherData=\"".$otherPlotData."\"";
}
else
{
	$msg = "otherData($otherPlotData) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $matchedLines)
{
	$RscriptsCMD = $RscriptsCMD." matchedLines=\"".$matchedLines."\"";
}
else
{
	$msg = "matchedLines($matchedLines) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (-e $outDIR)
{
	$RscriptsCMD = $RscriptsCMD." dir=\"".$outDIR."\"";
}
else
{
	$msg = "dir($outDIR) doesn't exist!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($format))
{
	$RscriptsCMD = $RscriptsCMD." format=\"".$format."\"";
}
else
{
	$msg = "format($format) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($gene))
{
	$RscriptsCMD = $RscriptsCMD."  geneName=\"".$gene."\"";
}
else
{
	$msg = "format($format) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($title))
{
	$RscriptsCMD = $RscriptsCMD."  title=\"".$title."\"";
}
else
{
	$msg = "title($title) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($xlab))
{
	$RscriptsCMD = $RscriptsCMD." xlab=\"".$xlab."\"";
}
else
{
	$msg = "xlab($xlab) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($ylab))
{
	$RscriptsCMD = $RscriptsCMD." ylab=\"".$ylab."\"";
}
else
{
	$msg = "ylab($ylab) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($titleCex))
{
	$RscriptsCMD = $RscriptsCMD." titleCex=".$titleCex."";
}
else
{
	$msg = "titleCex($titleCex) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($xlabCex))
{
	$RscriptsCMD = $RscriptsCMD." xlabCex=".$xlabCex."";
}
else
{
	$msg = "xlabCex($xlabCex) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($ylabCex))
{
	$RscriptsCMD = $RscriptsCMD." ylabCex=".$ylabCex."";
}
else
{
	$msg = "ylabCex($ylabCex) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($scatterYAxisCex))
{
	$RscriptsCMD = $RscriptsCMD." scatterYAxisCex=".$scatterYAxisCex."";
}
else
{
	$msg = "scatterYAxisCex($scatterYAxisCex) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($phenotyeMeanLineColor))
{
	$RscriptsCMD = $RscriptsCMD." phenotyeMeanLineColor=\"".$phenotyeMeanLineColor."\"";
}
else
{
	$msg = "phenotyeMeanLineColor($phenotyeMeanLineColor) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($phenotyeMeanLineType))
{
	$RscriptsCMD = $RscriptsCMD." phenotyeMeanLineType=\"".$phenotyeMeanLineType."\"";
}
else
{
	$msg = "phenotyeMeanLineType($phenotyeMeanLineType) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($phenotyeSDLineColor))
{
	$RscriptsCMD = $RscriptsCMD." phenotyeSDLineColor=\"".$phenotyeSDLineColor."\"";
}
else
{
	$msg = "phenotyeSDLineColor($phenotyeSDLineColor) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($phenotyeSDLineType))
{
	$RscriptsCMD = $RscriptsCMD." phenotyeSDLineType=\"".$phenotyeSDLineType."\"";
}
else
{
	$msg = "phenotyeSDLineType($phenotyeSDLineType) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($exonRegionColor))
{
	$RscriptsCMD = $RscriptsCMD." exonRegionColor=\"".$exonRegionColor."\"";
}
else
{
	$msg = "exonRegionColor($exonRegionColor) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($annotations))
{
	$RscriptsCMD = $RscriptsCMD." annotations=\"".$annotations."\"";
}
else
{
	$msg = "annotations($annotations) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($annotationColors))
{
	$RscriptsCMD = $RscriptsCMD." annotationColors=\"".$annotationColors."\"";
}
else
{
	$msg = "annotationColors($annotationColors) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($beanPlotNum))
{
	$RscriptsCMD = $RscriptsCMD." beanPlotNum=".$beanPlotNum."";
}
else
{
	$msg = "beanPlotNum($beanPlotNum) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($beanPlotXAxisLabelAngle))
{
	$RscriptsCMD = $RscriptsCMD." beanPlotXAxisLabelAngle=".$beanPlotXAxisLabelAngle;
}
else
{
	$msg = "beanPlotXAxisLabelAngle($beanPlotXAxisLabelAngle) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($beanPlotXAxisLableCex))
{
	$RscriptsCMD = $RscriptsCMD." beanPlotXAxisLableCex=".$beanPlotXAxisLableCex;
}
else
{
	$msg = "beanPlotXAxisLableCex($beanPlotXAxisLableCex) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($beanPlotXAxisLablePos1))
{
	$RscriptsCMD = $RscriptsCMD." beanPlotXAxisLablePos1=".$beanPlotXAxisLablePos1;
}
else
{
	$msg = "beanPlotXAxisLablePos1($beanPlotXAxisLablePos1) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($beanPlotXAxisLablePos2))
{
	$RscriptsCMD = $RscriptsCMD." beanPlotXAxisLablePos2=".$beanPlotXAxisLablePos2;
}
else
{
	$msg = "beanPlotXAxisLablePos2($beanPlotXAxisLablePos2) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

$RscriptsCMD = $RscriptsCMD." outFile=\"NULL\"";

if (defined($width))
{
	$RscriptsCMD = $RscriptsCMD." width=".$width;
}
else
{
	$msg = "width($width) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

if (defined($height))
{
	$RscriptsCMD = $RscriptsCMD." height=".$height;
}
else
{
	$msg = "height($height) is not defined!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

$msg = "The R script command line is :\n$RscriptsCMD";

logFile($log,$msg);

$cmd = system("$RscriptsCMD");

if ($cmd != 0)
{
	$msg ="Can't execute R script command line!";
	$msg = createErrMsg($msg);

	popErr($log,$msg);
}

exit(0);


#==================================================================
#   Perldoc Documentation
#==================================================================

__END__

=head1 NAME

geneZoom - This tool is a visualization tool that shows the frequency of variants in a predefined region for groups of individuals.

=head1 SYNOPSIS

geneZoom.pl [command] [options]

 Command:
   help                     Print out brief help message
   man                      Print the full documentation in man page style
   version                  Print the geneZoom version
   vcf                      The VCF file has SNP information
   gene                     The gene region will be plotted
   phenotypeFile            The phenotype has phenotype value and sample ID
   sampleFieldName          The field name of sample ID in the phenotype file
   phenotypeFieldName       The field name of phenotype value in the phenotype file
   phenotypeDelim           The delim in phenotype file
   snpList                  SNP list which you want to show in plot
   snpChrFieldName          The field name of CHR in SNP list
   snpPosFieldName          The field name of POS in SNP list
   snpChrPosFieldName       The field name of CHR:POS in SNP list
   snpDelim                 The delim in snp list
   lableSNPs                The SNP which will be labled in plot
   flags                    The annotation values, MAF range and colors. For example, splicing:0:0.01:red,readthrough:blue
   defaultIntron            The default intron lenght in plot
   title                    The titile of the plot
   xlab                     The xlab of the plot
   ylab                     The xlab of the plot
   titleCex                 The cex of title
   xlabCex                  The cex of xlab
   ylabCex                  The cex of ylab
   scatterYAxisCex          The cex of y axis
   phenotyeMeanLineColor    The color of mean value of all SNPs in gene region
   phenotyeMeanLineType     The line type of mean value of all SNPs in gene region
   phenotyeSDLineColor      The color of standard deviation value of all SNPs in gene region
   phenotyeSDLineType       The line type of standard deviation value of all SNPs in gene region
   exonRegionColor          The color of exon region
   beanPlotXAxisLabelAngle  The lable angle of bean plot x axis
   beanPlotXAxisLableCex    The cex of bean plot x axis
   beanPlotXAxisLablePos1   The position 1 of bean plot x axis lable
   beanPlotXAxisLablePos2   The position 2 of bean plot x axis lable
   width                    The width of plot
   height                   The height of plot
   format                   The format of plot
   outDIR                   The result directory


 Visit http://genome.sph.umich.edu/wiki/genezoom for more detailed documentation

=head1 COMMANDS

=over 8

=item B<help>

Print a brief help message and exits.

=item B<man>

Prints the manual page and exits.

=item B<version>

Prints the geneZoom version and exits.

=item B<vcf>

The VCF file has SNP information. This VCF should have header with sample ID.

=item B<gene>

The gene region will be plotted. For example, "PCSK9".

=item B<phenotypeFile>

The phenotype has phenotype value and sample ID. This file must have header to spcify which colum is phenotype value and sample ID.

=item B<sampleFieldName>

The field name of sample ID in the phenotype file.

=item B<phenotypeFieldName>

The field name of phenotype value in the phenotype file

=item B<phenotypeDelim>

The delim in phenotype file. It can be tab, blank or comma.

=item B<snpList>

SNP list which you want to show in plot. If you have a lot SNPs in the gene region, you can specify the SNPs only shown in the plot. Can be NULL.

=item B<snpChrFieldName>

The field name of CHR in SNP list. If you don't define snpList, this Can be NULL.

=item B<snpPosFieldName>

The field name of POS in SNP list. If you don't define snpList, this Can be NULL.

=item B<snpChrPosFieldName>

The field name of CHR:POS in SNP list. If you don't define snpList, this Can be NULL.

=item B<snpDelim>

The delim in snp list. It can be tab, blank or comma. If you don't define snpList, this Can be NULL.

=item B<lableSNPs>

The SNP which will be labled in plot. Can be NULL.

=item B<flags>

The annotation values, MAF range and colors. For example, splicing:0:0.01:red,readthrough:blue. You must specify annotation value,MAF range and color can be empty. The tool will use the default MAF range(0,0.5), and random select one color.

=item B<defaultIntron>

The default intron lenght in plot. When draw enxon region, tool re-define the intron region with this value. Can be NULL.

=item B<title>

The titile of the plot. Can be NULL.

=item B<xlab>

The xlab of the plot. Can be NULL.

=item B<ylab>

The xlab of the plot. Can be NULL.

=item B<titleCex>

The cex of title. This value can change the size of title. Can be NULL.

=item B<xlabCex>

The cex of xlab. This value can change the size of xlab. Can be NULL.

=item B<ylabCex>

The cex of ylab. This value can change the size of ylab. Can be NULL.

=item B<scatterYAxisCex>

The cex of y axis. This value can change the size of y axis. Can be NULL.

=item B<phenotyeMeanLineColor>

The color of mean value of all SNPs in gene region. Can be NULL.

=item B<phenotyeMeanLineType>

The line type of mean value of all SNPs in gene region. Can be NULL.

=item B<phenotyeSDLineColor>

The color of standard deviation value of all SNPs in gene region. Can be NULL.

=item B<phenotyeSDLineType>

The line type of standard deviation value of all SNPs in gene region. Can be NULL.

=item B<exonRegionColor>

The color of exon region. Can be NULL.

=item B<beanPlotXAxisLabelAngle>

The lable angle of bean plot x axis. Can be NULL.

=item B<beanPlotXAxisLableCex>

The cex of bean plot x axis. Can be NULL.

=item B<beanPlotXAxisLablePos1>

The position 1 of bean plot x axis lable. Can be NULL.

=item B<beanPlotXAxisLablePos2>

The position 2 of bean plot x axis lable. Can be NULL.

=item B<width>

The width of plot. Default is 14.1 . Can be NULL.

=item B<height>

The height of plot. Default is 10. Can be NULL.

=item B<format>

The format of plot. It can be pdf,tiff and png. Can be NULL.

=item B<outDIR>

The result directory. All intermediate files and result plot file are in this folder.

=back

=head1 DESCRIPTION

B<geneZoom> is an efficient and flexible software shows the frequency of variants in a predefined region for groups of individuals.

Visit http://genome.sph.umich.edu/wiki/genezoom for more detailed documentation

=cut
