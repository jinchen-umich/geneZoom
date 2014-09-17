#! /usr/bin/perl -w

use strict;
use warnings;
use Switch;

sub getDateAndTime
{
	my ($sec,$min,$hour,$day,$mon,$year,$weekday,$yeardate,$savinglightday) = (localtime(time));
	$sec = ($sec < 10)? "0$sec":$sec;
	$min = ($min < 10)? "0$min":$min;
	$hour = ($hour < 10)? "0$hour":$hour;
	$day = ($day < 10)? "0$day":$day;
	$mon = ($mon < 9)? "0".($mon+1):($mon+1);
	$year += 1900;

	return ($sec,$min,$hour,$day,$mon,$year,$weekday,$yeardate,$savinglightday);
}

sub getFileType
{
	my ($file) = @_;
	
	my $cmd = `file $file`;
	
	my $type = "NA";
	
	if ($cmd =~ /ASCII\ text/)
	{
		$type = "ASCII";
	}
	elsif ($cmd =~ /gzip\ compressed\ data/)
	{
		$type = "gzip";
	}
	
	return ($type);
}

sub getFileName
{
	my ($txt) = @_;

	chomp $txt;

	my @fields = split(/\//,$txt);
	my $k = int(@fields) - 1;
	my $name = $fields[$k];

	return ($name);
}

sub createErrMsg
{
	my ($txt) = @_;

	my $ret = "Error : ".$txt;

	return ($ret);
}

sub logFile
{
	my ($log,$msg) = @_;

	open (OUT,">>".$log) || die "can't write to the log file:$log!\n";

	if ($msg !~ /^Error/i)
	{
		print "$msg\n";
	}

	print OUT "$msg\n";

	close OUT;
}

sub popErr
{
	my ($log,$errmsg) = @_;

	if ($errmsg =~ /^Error/i)
	{
		print "$errmsg\n";

		print "Program running is terminated!\n";
		
		logFile($log,$errmsg);
		
		exit(1);
	}
}

sub readColorList
{
	my ($dir_ref,$hash_ref) = @_;

	my $errmsg = "NA";

	my $thisDIR = $$dir_ref;

	if ($thisDIR !~ /\/$/)
	{
		$thisDIR = $thisDIR."/";
	}

	$thisDIR = $thisDIR."../ref/";

	if (!(-e $thisDIR))
	{
		$errmsg = "Directory ($thisDIR) doesn't exist!";
		$errmsg = createErrMsg($errmsg);
	}
	else
	{
		my $file = $thisDIR."colors.txt";

		open (IN,$file) || die "can't open the file:$file!\n";

		my $readline;

		while (defined($readline=<IN>))
		{
			chomp $readline;

			my $lowcase = lc($readline);

			$hash_ref->{$lowcase} = 1;
		}

		close IN;
	}	

	return ($errmsg);
}

sub checkColor
{
	my ($color_ref,$hash_ref) = @_;

	my $errmsg = "NA";

	my $lowcase = lc($$color_ref);

	if (!(exists($hash_ref->{$lowcase})))
	{
		$errmsg = "Can't find the color($lowcase) in R!";
		$errmsg = createErrMsg($errmsg);
	}

	return ($errmsg);
}

sub readLineTypeList
{
	my ($dir_ref,$hash_ref) = @_;

	my $errmsg = "NA";

	my $thisDIR = $$dir_ref;

	if ($thisDIR !~ /\/$/)
	{
		$thisDIR = $thisDIR."/";
	}

	$thisDIR = $thisDIR."../ref/";

	if (!(-e $thisDIR))
	{
		$errmsg = "Directory ($thisDIR) doesn't exist!";
		$errmsg = createErrMsg($errmsg);
	}
	else
	{
		my $file = $thisDIR."lineTypes.txt";

		open (IN,$file) || die "can't open the file:$file!\n";

		my $readline;

		while (defined($readline))
		{
			chomp $readline;

			my $lowcase = lc($readline);

			$hash_ref->{$lowcase} = 1;
		}

		close IN;
	}	

	return ($errmsg);
}

sub checkLineType
{
	my ($lineType_ref,$hash_ref) = @_;

	my $errmsg = "NA";

	my $lowcase = lc($$lineType_ref);

	if (!(exists($hash_ref->{$lowcase})))
	{
		$errmsg = "Can't find line type($lowcase) in R!";
		$errmsg = createErrMsg($errmsg);
	}

	return ($errmsg);
}

sub verifyPhenotypeFile
{
	my ($file,$sname,$phname,$delim) = @_;

	my $errmsg = "NA";

  if (!(-e $file))
  {
		$errmsg = "The phenotype file ($file) doesn't exist!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}

	if (($delim !~ /^tab$/i)&&($delim !~ /^comma$/i)&&($delim !~ /^blank$/i))
	{
		$errmsg = "The delim should be tab,comma or blank!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}

	my $phenotypeFileType = getFileType($file);
		
	if ($phenotypeFileType eq "gzip")
	{
		open(IN, "gunzip -c $file |") || die "can't open the file:$file!\n";
	}
	elsif ($phenotypeFileType eq "ASCII")
	{
		open (IN,$file) || die "can't open the file:$file!\n";
	}
	else
	{
		$errmsg = "The phenotype file ($file) has the wrong file format! It should be ASCII or gz file!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}
		
	my $readline = <IN>;

	chomp $readline;

	my @fields;
	undef @fields;

	switch ($delim)
	{
		case /^tab$/i
		{
			@fields = split(/\t/,$readline);
		}
		case /^comma$/i
		{
			@fields = split(/\,/,$readline);
		}
		case /^blank$/i
		{
			@fields = split(/\ +/,$readline);
		}
		else
		{
			$errmsg = "The delim should be tab,comma or blank!";
			$errmsg = createErrMsg($errmsg);

			close IN;

			return ($errmsg);
		}
	}

	my $sampleClmn = -1;
	my $phenotypeClmn = -1;

	for (my $i = 0; $i < int(@fields); $i++)
	{
		if ($fields[$i] =~ /^$sname$/i)
		{
			$sampleClmn = $i;
		}

		if ($fields[$i] =~ /^$phname$/i)
		{
			$phenotypeClmn = $i;
		}
	}

	if ($sampleClmn == -1)
	{
		$errmsg = "Can't find sample list in your phenotype file!";
		$errmsg = createErrMsg($errmsg);
	}

	if ($phenotypeClmn == -1)
	{
		$errmsg = "Can't find phenotype list in your phenotype file!";
		$errmsg = createErrMsg($errmsg);
	}

	close IN;
	
	return ($errmsg);
}

sub verifySNPListFile
{
	my ($file,$chrname,$posname,$chrposname,$delim) = @_;

	my $errmsg = "NA";

  if (!(-e $file))
  {
		$errmsg = "The snpList($file) doesn't exist!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}

	if (($delim !~ /^tab$/i)&&($delim !~ /^comma$/i)&&($delim !~ /^blank$/i))
	{
		$errmsg = "The delim should be tab,comma or blank!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}

	my $snpListFileType = getFileType($file);
		
	if ($snpListFileType eq "gzip")
	{
		open(IN, "gunzip -c $file |") || die "can't open the file:$file!\n";
	}
	elsif ($snpListFileType eq "ASCII")
	{
		open (IN,$file) || die "can't open the file:$file!\n";
	}
	else
	{
		$errmsg = "The snp list ($file) has the wrong file format! It should be ASCII or gz file!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}
		
	my $readline = <IN>;

	chomp $readline;

	my @fields;
	undef @fields;
		
	switch ($delim)
	{
		case /^tab$/i
		{
			@fields = split(/\t/,$readline);
		}
		case /^comma$/i
		{
			@fields = split(/\,/,$readline);
		}
		case /^blank$/i
		{
			@fields = split(/\ +/,$readline);
		}
		else
		{
			$errmsg = "The delim should be tab,comma or blank!";
			$errmsg = createErrMsg($errmsg);

			close IN;

			return ($errmsg);
		}
	}

	my $chrClmn = -1;
	my $posClmn = -1;
	my $chrposClmn = -1;

	for (my $i = 0; $i < int(@fields); $i++)
	{
		if (($chrname ne "NA")&&($posname ne "NA"))
		{
			if ($fields[$i] =~ /^$chrname$/i)
			{
				$chrClmn = $i;
			}

			if ($fields[$i] =~ /^$posname$/i)
			{
				$posClmn = $i;
			}
		}
		elsif ($chrposname ne "NA")
		{
			if ($fields[$i] =~ /^$chrposname$/i)
			{
				$chrposClmn = $i;
			}
		}
	}

	if (($chrname ne "NA")&&($posname ne "NA"))
	{
		if ($chrClmn == -1)
		{
			$errmsg = "Can't find snps' chr in your snp list file!";
			$errmsg = createErrMsg($errmsg);
		}

		if ($posClmn == -1)
		{
			$errmsg = "Can't find snps' pos in your snp list file!";
			$errmsg = createErrMsg($errmsg);
		}
	}
	elsif ($chrposname ne "NA")
	{
		if ($chrposClmn == -1)
		{
			$errmsg = "Can't find snps' chr:pos in your snp list file!";
			$errmsg = createErrMsg($errmsg);
		}
	}
	else
	{
		$errmsg = "Can't find snps' chr:pos in your snp list file!";
		$errmsg = createErrMsg($errmsg);
	}

	close IN;
	
	return ($errmsg);
}

sub coordinateTransformation
{
	my ($x0,$x1,@arr1) = @_;

	my $errmsg = "NA";

	my @arr2;
	undef @arr2;

	if ($x0 == $x1)
	{
		$errmsg = "can't do coordinate transformation with ($x0,$x1)!";
	}
	else
	{
		my $k = 1 / ($x1 - $x0);
		my $b = $x0 / ($x0 - $x1);

		for (my $i = 0; $i < int(@arr1); $i++)
		{
			$arr2[$i] = $k * $arr1[$i] + $b;
		}
	}

	return ($errmsg,@arr2);
}

sub transformGeneRegion
{													
## convert exon position to new regions
	my ($geneStart,$geneEnd,$exonStarts,$exonEnds,$defaultIntron) = @_;
	
	my $geneLength = $geneEnd - $geneStart;

## calculate exons' length
	my $lengthOfExons = 0;
	my @starts = split(/\,/,$exonStarts);
	my @ends = split(/\,/,$exonEnds);

	for (my $i = 0; $i < int(@starts); $i++)
	{
		$lengthOfExons = $lengthOfExons + abs($ends[$i] - $starts[$i]);
	}

## calculate introns' length
	my $lengthOfIntrons = $geneLength - $lengthOfExons;

## get number of introns
	my $numOfIntrons = int(@starts) + 1;

## calculate new intron length
#	my $newIntronIntval = $lengthOfIntrons / $numOfIntrons;
	
#	$newIntronIntval = int($newIntronIntval / 1000) * 100;
	
#	if ($newIntronIntval > $defaultIntron)
#	{
#		$newIntronIntval = $defaultIntron;
#	}
	my $newIntronIntval = $geneLength * 0.15;
	$newIntronIntval = $newIntronIntval / $numOfIntrons;

## calculate the new exons
	my $newExonStarts = "NA";
	my $newExonEnds = "NA";
	
	my $errmsg = "NA";

	if (int(@starts) == 0)
	{
		$errmsg = "No exon region is on this gene!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$newExonStarts,$newExonEnds);
	}

	if (int(@starts) == 1)
	{
		$newExonStarts = $geneStart + $newIntronIntval;
		$newExonEnds = $geneEnd - $newIntronIntval;

		return ($errmsg,$newExonStarts,$newExonEnds);
	}

	if ($lengthOfExons <= 0)
	{
		$errmsg = "No exon region is on this gene!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$newExonStarts,$newExonEnds);
	}

	if ($lengthOfIntrons < 0)
	{
		$errmsg = "All exon region length is greater than gene region!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$newExonStarts,$newExonEnds);
	}

	if ($lengthOfIntrons == 0)
	{
		$newExonStarts = $geneStart + $newIntronIntval;
		$newExonEnds = $geneEnd - $newIntronIntval;

		return ($errmsg,$newExonStarts,$newExonEnds);
	}

## calculate new exon length
	my $newExonLength = abs($geneEnd - $geneStart) - $newIntronIntval * $numOfIntrons;

	if ($newExonLength <= 0)
	{
		$errmsg = "The exons are wrong!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$newExonStarts,$newExonEnds);
	}

	my $ratio = $newExonLength / $lengthOfExons;

## calculate new exon starts and ends
	my $thisExonLength = abs($ends[0] - $starts[0]);
	$starts[0] = $geneStart + $newIntronIntval;
	$ends[0] = $starts[0] + $thisExonLength * $ratio;

	for (my $i = 1; $i < int(@starts); $i++)
	{
		$thisExonLength = abs($ends[$i] - $starts[$i]);

		$starts[$i] = $ends[$i-1] + $newIntronIntval;

		$ends[$i] = $starts[$i] + $thisExonLength * $ratio;
	}

	$newExonStarts = $starts[0];
	$newExonEnds = $ends[0];

	for (my $i = 1; $i < int(@starts); $i++)
	{
		$newExonStarts = $newExonStarts.",".$starts[$i];	
		$newExonEnds = $newExonEnds.",".$ends[$i];
	}

	return ($errmsg,$newExonStarts,$newExonEnds);
}

sub getGeneRegion
{
	my ($ref,$gene) = @_;
	
	open (IN,$ref) || die "can't open the file:$ref!\n";
	
	my $readline;

	my $geneChr = "NA";
	my $geneStart = "NA";
	my $geneEnd = "NA";
	my $exonStarts = "NA";
	my $exonEnds = "NA";

	my $errmsg = "NA";
	
	while (defined($readline=<IN>))
	{
		chomp $readline;
		
		my @fields = split(/\t/,$readline);
		my $thisChr = $fields[2];
		my $thisStart = $fields[4];
		my $thisEnd = $fields[5];
		my $thisGeneName = $fields[12];
		
		$thisChr =~ s/^chr//i;
		
		if ($thisChr =~ /^x$/i)
		{
			$thisChr = 23;
		}
		elsif ($thisChr =~ /^y$/i)
		{
			$thisChr = 24;
		}
		
		if ($gene =~ /^$thisGeneName$/i)
		{
			$geneChr = $thisChr;
			$geneStart = $thisStart;
			$geneEnd = $thisEnd;
			$exonStarts = $fields[9];
			$exonEnds = $fields[10];
			
			last;
		}
	}
	
	close IN;
	
	if (($geneChr eq "NA")||($geneStart eq "NA")||($geneEnd eq "NA")||($exonStarts eq "NA")||($exonEnds eq "NA"))
	{
		$errmsg = "Can't find the gene region for $gene!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
	}

	if (($geneStart !~ /^\d+$/)||($geneEnd !~ /^\d+$/))
	{
		$errmsg = "Can't find the gene region for $gene!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
	}

	if ($geneStart >= $geneEnd)
	{
		my $tmp = $geneStart;
		$geneStart = $geneEnd;
		$geneEnd = $tmp;
	}

## clean and verify exon region data
	$exonStarts =~ s/\,$//;
	$exonEnds =~ s/\,$//;

	my @starts = split(/\,/,$exonStarts);
	my @ends = split(/\,/,$exonEnds);

	my $numOfStarts = int(@starts);
	my $numOfEnds = int(@ends);

	if ($numOfStarts != $numOfEnds)
	{
		$errmsg = "exonStarts($exonStarts) and exonEnds($exonEnds) have the different elements for the gene($gene)!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
	}

	for (my $i = 0; $i < $numOfStarts; $i++)
	{
		if ($starts[$i] !~ /^\d+$/)
		{
			$errmsg = "one exon start position is wrong($starts[$i],$exonStarts)!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
		}
	}

	for (my $i = 0; $i < $numOfEnds; $i++)
	{
		if ($ends[$i] !~ /^\d+$/)
		{
			$errmsg = "one exon end position is wrong($ends[$i],$exonEnds)!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
		}
	}

	if ($geneStart > $starts[0])
	{
		$errmsg = "The first exon($starts[0]) is starting at a wrong position(geneStart = $geneStart)!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
	}

	if ($geneEnd < $ends[$numOfEnds - 1])
	{
		$errmsg = "The last exon($ends[$numOfEnds - 1]) is ending at a wrong position(geneEnd = $geneEnd)!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
	}

	if ($starts[0] > $ends[0])
	{
		$errmsg = "One exon region ($starts[0],$ends[0]) is wrong!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
	}

	my $lastPosition = $ends[0];

	for (my $i = 1; $i < $numOfStarts; $i++)
	{
		if ($lastPosition > $starts[$i])
		{
			$errmsg = "One intron region ($lastPosition,$starts[$i]) is wrong!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
		}

		if ($starts[$i] > $ends[$i])
		{
			$errmsg = "One exon region ($starts[$i],$ends[$i]) is wrong!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
		}

		$lastPosition = $ends[$i];
	}

	return ($errmsg,$geneChr,$geneStart,$geneEnd,$exonStarts,$exonEnds);
}

sub changeAnnotation
{
	my ($anno) = @_;

	my $ret;

	if ($anno =~ /^splice$/i)
	{
		$ret = "splicing";
	}
	elsif ($anno =~ /^nonsense$/i)
	{
		$ret = "stopgain";
	}
	elsif ($anno =~ /^readthrough$/i)
	{
		$ret = "stoploss";
	}
	elsif ($anno =~ /^missense$/i)
	{
		$ret = "nonsynonymous";
	}
	else
	{
		$ret = $anno;
	}

	return ($ret);
}

sub colorRandomSelect
{
	my ($hash_ref) = @_;

	my $ret	= "NA";

	srand time();

	my $k = keys %{$hash_ref};
	my $r = int(rand($k));

	while (my ($color,$v) = each %{$hash_ref})
	{
		if ($r == 0)
		{
			$ret = $color;

			delete ($hash_ref->{$color});

			last;
		}
		else
		{
			$r = $r - 1;
		}
	}

	return ($ret);
}

sub readAnnotationFlags
{
	my ($txt,%cHash) = @_;
	
	my $annotationStr				= "NA";
	my $annotationColorStr	= "NA";
	my $errmsg							= "NA";

	my %fHash;
	undef %fHash;

	my @fields = split(/\,/,$txt);

## split flags to %fHash and $annotationStr	
	for (my $i = 0; $i < int(@fields); $i++)
	{
		my $flag = $fields[$i];

#		$flag =~ s/^\(//;
#		$flag =~ s/\)$//;

		my @tmp = split(/\:/,$flag);

		my $k			= int(@tmp);
		my $anno	= "NA";
		my $start	= "NA";
		my $end		= "NA";
		my $color	= "NA";

		switch ($k)
		{
			case 1
			{
				$anno		= $tmp[0];
				$start	= 0;
				$end		= 0.5;
				$color	= "NA";
			}
			case 2
			{
				$anno		= $tmp[0];
				$start	= 0;
				$end		= 0.5;
				$color	= $tmp[1];
			}
			case 3
			{
				$anno		= $tmp[0];
				$start	= $tmp[1];
				$end		= $tmp[2];
				$color  = $tmp[1];
			}
			case 4
			{
				$anno		= $tmp[0];
				$start	= $tmp[1];
				$end		= $tmp[2];
				$color	= $tmp[3];
			}
			else
			{
				$errmsg = "flag($fields[$i]) format is wrong!";
				$errmsg = createErrMsg($errmsg);

				return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
			}
		}

		if (($start !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)||($end !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/))
		{
			$errmsg = "one flag range is wrong(start = $start,end = $end)!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
		}

		if ($start < 0)
		{
			$errmsg = "one flag range is wrong(start = $start,end = $end)!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
		}

		if ($end > 0.5)
		{
			$errmsg = "one flag range is wrong(start = $start,end = $end)!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
		}

		$anno = changeAnnotation($anno);

		if (exists($fHash{$anno}))
		{
			$errmsg = "Two flags are same($anno)!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
		}
		else
		{
			$fHash{$anno} = "$start\t$end\t$color";

			if ($annotationStr eq "NA")
			{
				$annotationStr = $anno;
			}
			else
			{
				$annotationStr = $annotationStr.",".$anno;
			}
		}
	}

## chekc all colors are defined. If one annotation is not given a color,random select one for it.
## The "black" is given to "other" group.
	delete ($cHash{"black"});

## delete all used colors
	while (my ($anno,$v) = each %fHash)
	{
		my @tmp = split(/\t/,$v);

		my $start = $tmp[0];
		my $end   = $tmp[1];
		my $color = $tmp[2];

		if ($color ne "NA")
		{
			if (exists($cHash{$color}))
			{
				delete ($cHash{$color});
			}
			else
			{
				$errmsg = "One color ($color) is used more than 1 time!";
				$errmsg = createErrMsg($errmsg);
				
				return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
			}
		}

	}

## give a color to NA
	while (my ($anno,$v) = each %fHash)
	{
		my @tmp = split(/\t/,$v);

		my $start	=	$tmp[0];
		my $end		=	$tmp[1];
		my $color	=	$tmp[2];

		if ($color eq "NA")
		{
			$color = &colorRandomSelect(\%cHash);

			if ($color eq "NA")
			{
				$errmsg = "Can't random select one color from color hash!";
				$errmsg = createErrMsg($errmsg);

				return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
			}

			$fHash{$anno} = "$start\t$end\t$color";
		}
		else
		{
##		all defined colors are deleted on prev steps.
		}
	}

## create $annotationColorStr
	@fields = split(/\,/,$annotationStr);

	for (my $i = 0; $i < int(@fields); $i++)
	{
		if (exists($fHash{$fields[$i]}))
		{
			my @tmp	= split(/\t/,$fHash{$fields[$i]});

			my $color	= $tmp[2];

			if ($annotationColorStr eq "NA")
			{
				$annotationColorStr = $color;
			}
			else
			{
				$annotationColorStr = $annotationColorStr.",".$color;
			}
		}
		else
		{
			$errmsg = "Can't find one annotation ($fields[$i])!";
			$errmsg = createErrMsg($errmsg);

			return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
		}
	}

	return ($errmsg,$annotationStr,$annotationColorStr,%fHash);
}

sub readSNPList
{
	my ($file,$chrname,$posname,$chrposname,$delim,$hash) = @_;

	my $errmsg = "NA";

	if (!(-e $$file))
	{
		$errmsg = "snpList($$file) doesn't exist!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}

	my $snpListType = getFileType($$file);
			
	if ($snpListType eq "gzip")
	{
		open(IN, "gunzip -c $$file |") || die "can't open the file:$$file!\n";
	}
	elsif ($snpListType eq "ASCII")
	{
		open (IN,$$file) || die "can't open the file:$$file!\n";
	}
	else
	{
		$errmsg = "snpList($$file) has the wrong file format! It should be ASCII or gz file!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}
		
	my $readline = <IN>;

	chomp $readline;

	my @fields;
	undef @fields;

	switch ($$delim)
	{
		case /^tab$/i
		{
			@fields = split(/\t/,$readline);
		}
		case /^comma$/i
		{
			@fields = split(/\,/,$readline);
		}
		case /^blank$/i
		{
			@fields = split(/\ +/,$readline);
		}
		else
		{
			$errmsg = "The delim should be tab, comma or blank!";
			$errmsg = createErrMsg($errmsg);

			close IN;

			return ($errmsg);
		}
	}

	my $chrClmn = -1;
	my $posClmn = -1;
	my $chrposClmn = -1;
		
	for (my $i = 0; $i < int(@fields); $i++)
	{
		if (($$chrname ne "NA")&&($$posname ne "NA"))
		{
			if ($fields[$i] =~ /^$$chrname$/i)
			{
				$chrClmn = $i;
			}
			elsif ($fields[$i] =~ /^$$posname$/i)
			{
				$posClmn = $i;
			}
		}
		elsif ($$chrposname ne "NA")
		{
			if ($fields[$i] =~ /^$$chrposname$/i)
			{
				$chrposClmn = $i;
			}
		}
	}

	if (($$chrname ne "NA")&&($$posname ne "NA"))
	{
		if ($chrClmn == -1)
		{
			$errmsg = "can't find snps' chr in your snp list file!";
			$errmsg = createErrMsg($errmsg);

			close IN;

			return ($errmsg);
		}

		if ($posClmn == -1)
		{
			$errmsg = "can't find snps' pos in your snp list file!";
			$errmsg = createErrMsg($errmsg);

			close IN;

			return ($errmsg);
		}
	}
	elsif ($$chrposname ne "NA")
	{
		if ($chrposClmn == -1)
		{
			$errmsg = "can't find snps' chr:pos in your snp list file!";
			$errmsg = createErrMsg($errmsg);

			close IN;

			return ($errmsg);
		}
	}

	while (defined($readline=<IN>))
	{
		chomp $readline;
			
		undef @fields;

		switch ($$delim)
		{
			case /^tab$/i
			{
				@fields = split(/\t/,$readline);
			}
			case /^comma$/i
			{
				@fields = split(/\,/,$readline);
			}
			case /^blank$/i
			{
				@fields = split(/\ +/,$readline);
			}
			else
			{
				$errmsg = "The delim should be tab, comma or blank!";
				$errmsg = createErrMsg($errmsg);

				close IN;
					
				return ($errmsg);
			}
		}

		if (($chrClmn != -1)&&($posClmn != -1))
		{
			my $chr = $fields[$chrClmn];
			my $pos = $fields[$posClmn];

			$chr =~ s/^chr//i;
	
			if ($chr =~ /^x$/i)
			{
				$chr = 23;
			}
			elsif ($chr =~ /^y$/i)
			{
				$chr = 24;
			}
			
			if (($chr !~ /^\d+$/)||($pos !~ /^\d+$/))
			{
				$errmsg = "snpList($$file) has some non-SNP data($chr,$pos)!\n";
				$errmsg = createErrMsg($errmsg);

				last;
			}
			else
			{
				if (($chr < 1)&&($chr > 24))
				{
					$errmsg = "snpList ($$file) has some non-SNP data($chr,$pos)!\n";
					$errmsg = createErrMsg($errmsg);

					last;
				}
				else
				{
					my $snp = $chr.":".$pos;
						
					$hash->{$snp} = 1;
				}
			}
		}
		elsif ($chrposClmn != -1)
		{
			my @tmp = split(/\:/,$fields[$chrposClmn]);	
			my $chr = $tmp[0];
			my $pos = $tmp[1];

			$chr =~ s/^chr//i;
	
			if ($chr =~ /^x$/i)
			{
				$chr = 23;
			}
			elsif ($chr =~ /^y$/i)
			{
				$chr = 24;
			}
			
			if (($chr !~ /^\d+$/)||($pos !~ /^\d+$/))
			{
				$errmsg = "snpList($$file) has some non-SNP data($chr,$pos)!\n";
				$errmsg = createErrMsg($errmsg);

				last;
			}
			else
			{
				if (($chr < 1)&&($chr > 24))
				{
					$errmsg = "snpList ($$file) has some non-SNP data($chr,$pos)!\n";
					$errmsg = createErrMsg($errmsg);

					last;
				}
				else
				{
					my $snp = $chr.":".$pos;
						
					$hash->{$snp} = 1;
				}
			}
		}
	}	
			
	close IN;

	return ($errmsg);
}

sub runANNOVARForVCF
{
	my ($vcf,$dir,$bin,$hash) = @_;

	my $errmsg = "NA";

## create annovar input file
	my $vcfType = getFileType($$vcf);
	
	if ($vcfType eq "gzip")
	{
		open(IN, "gunzip -c $$vcf |") || die "can't open the file:$$vcf!\n";
	}
	elsif ($vcfType eq "ASCII")
	{
		open (IN,$$vcf) || die "can't open the file:$$vcf!\n";
	}
	else
	{
		$errmsg = "vcf($$vcf) has the wrong file format! It should be ASCII or gz file!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}
	
	my $annovarin = $$dir."annovar.in";
	
	open (OUT,">".$annovarin) || die "can't write to the file:$annovarin!\n";
	
	my $readline;
	
	while (defined($readline=<IN>))
	{
		if ($readline !~ /^\#/)
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
			
			my $start = $fields[1];
			my $ref = $fields[3];
			my $alt = $fields[4];
			
			my $len = length($ref) - 1;
			my $end = $start + $len;
			
			print OUT "$chr\t$start\t$end\t$ref\t$alt\n";
		}
	}
	
	close IN;
	close OUT;
	
	my $cmd = `perl $$bin/../scripts/annotate_variation.pl $annovarin -buildver hg19 $$bin/../ref/humandb/`;
	
## read annovar results to hash;
	my $exonic_variant_function = $$dir."annovar.in.exonic_variant_function";
	my $variant_function = $$dir."annovar.in.variant_function";
	
	open (IN,$exonic_variant_function) || die "can't open the file:$exonic_variant_function!\n";

	while (defined($readline=<IN>))
	{
		chomp $readline;
		
		my @fields = split(/\t/,$readline);
		
		my $anno = $fields[1];
		my $chr = $fields[3];
		my $pos = $fields[4];
		
		$anno =~ s/\ SNV$//;
		
		my $snp = $chr.":".$pos;
		
		$hash->{$snp} = $anno;
	}
	
	close IN;
	
	open (IN,$variant_function) || die "can't open the file:$variant_function!\n";
	
	while (defined($readline=<IN>))
	{
		chomp $readline;
		
		my @fields = split(/\t/,$readline);
		
		my $anno = $fields[0];
		my $snp = $fields[2].":".$fields[3];
		
		if (exists($hash->{$snp}))
		{
			# do nothing
		}
		else
		{
			$hash->{$snp} = $anno;
		}
	}
	
	close IN;
	
	return ($errmsg);
}

sub readPhenotypeFile
{
	my ($vcfFile,$phenotypeFile,$sname,$phname,$delim,$hash) = @_;

	my $errmsg = "NA";

## read samples in vcf
	my $vcfFileType = getFileType($$vcfFile);

	if ($vcfFileType eq "gzip")
	{
		open(IN, "gunzip -c $$vcfFile |") || die "can't open the file:$$vcfFile!\n";
	}
	elsif ($vcfFileType eq "ASCII")
	{
		open (IN,$$vcfFile) || die "can't open the file:$$vcfFile!\n";
	}
	else
	{
		$errmsg = "The vcf file($$vcfFile) has the wrong file format! It should be ASCII or gz file!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}

	my $readline;

	while (defined($readline=<IN>))
	{
		if ($readline =~ /^\#CHROM/)
		{
			chomp $readline;

			my @fields = split(/\t/,$readline);

			for (my $i = 9; $i < int(@fields); $i++)
			{
				$hash->{$fields[$i]} = "NA";
			}

			last;
		}
	}

	close IN;

	my $k = keys %{$hash};

	if ($k <= 0)
	{
		$errmsg = "Can't find sample ID in your VCF file. Please check VCF file has headers starting with #CHROM!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}

## read samples and phenotype values from phonetype file
	my $phenotyeFileType = getFileType($$phenotypeFile);
	
	if ($phenotyeFileType eq "gzip")
	{
		open(IN, "gunzip -c $$phenotypeFile |") || die "can't open the file:$$phenotypeFile!\n";
	}
	elsif ($phenotyeFileType eq "ASCII")
	{
		open (IN,$$phenotypeFile) || die "can't open the file:$$phenotypeFile!\n";
	}
	else
	{
		$errmsg = "The phenotype File($$phenotypeFile) has the wrong file format! It should be ASCII or gz file!";
		$errmsg = createErrMsg($errmsg);

		return ($errmsg);
	}
	
	$readline = <IN>;
	
	chomp $readline;
	
	my @fields;
	undef @fields;

	switch ($$delim)
	{
		case /^tab$/i
		{
			@fields = split(/\t/,$readline);
		}
		case /^comma$/i
		{
			@fields = split(/\,/,$readline);
		}
		case /^blank$/i
		{
			@fields = split(/\ +/,$readline);
		}
		else
		{
			$errmsg = "The delim should be tab, comma or blank!";
			$errmsg = createErrMsg($errmsg);

			close IN;

			return ($errmsg);
		}
	}

	my $sampleClmn = -1;
	my $phenotypeClmn = -1;
	
	for (my $i = 0; $i < int(@fields); $i++)
	{
		if ($fields[$i] =~ /^$$sname$/i)
		{
			$sampleClmn = $i;
		}
		elsif ($fields[$i] =~ /^$$phname$/i)
		{
			$phenotypeClmn = $i;
		}
	}
	
	if ($sampleClmn == -1)
	{
		$errmsg = "can't find the sample ID column in phenotype file!";
		$errmsg = createErrMsg($errmsg);

		close IN;

		return ($errmsg);
	}

	if ($phenotypeClmn == -1)
	{
		$errmsg = "can't find phenotype column in phenotype file!";
		$errmsg = createErrMsg($errmsg);

		close IN;

		return ($errmsg);
	}
	
	while (defined($readline=<IN>))
	{
		chomp $readline;
	
		switch ($$delim)
		{
			case /^tab$/i
			{
				@fields = split(/\t/,$readline);
			}
			case /^comma$/i
			{
				@fields = split(/\,/,$readline);
			}
			case /^blank$/i
			{
				@fields = split(/\ +/,$readline);
			}
			else
			{
				$errmsg = "The delim should be tab, comma or blank!";
				$errmsg = createErrMsg($errmsg);

				close IN;
				return ($errmsg);
			}
		}

		my $thisSample = $fields[$sampleClmn];
		my $thisPhenotype = $fields[$phenotypeClmn];

		if ($thisPhenotype !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
		{
			$errmsg = "phenotype($thisPhenotype) is wrong format($readline)!";
			$errmsg = createErrMsg($errmsg);

			last;
		}
	
		if (exists($hash->{$thisSample}))
		{
			$hash->{$thisSample} = $thisPhenotype;
		}
	}

	close IN;

	while (my ($key,$value) = each %{$hash})
	{
		if ($value eq "NA")
		{
			delete ($hash->{$key});
		}
	}

	$k = keys %{$hash};

	if ($k <= 0)
	{
		$errmsg = "No sample overlap in both VCF file and phenotype file!";
		$errmsg = createErrMsg($errmsg);
	}

	return ($errmsg);
}

sub recreateAnnotationAndColorStr
{
	my ($file,$annotationStr,$colorStr) = @_;

	my $errmsg = "NA";

	my %annoHash;
	undef %annoHash;
	
	open (IN,$file) || die "can't open the file:$file!\n";
	
	my $readline = <IN>;
		
	while (defined($readline=<IN>))
	{
		chomp $readline;
		
		my @fields = split(/\t/,$readline);
		
		my $anno  = $fields[2];
		my $color = $fields[3];
		
		$annoHash{$anno} = $color;
	}
	
	close IN;
	
	my @annoArr   = split(/\,/,$annotationStr);
	my @colorArr  = split(/\,/,$colorStr);
				  
	my $newAnnoStr  = "NA";
	my $newColorStr = "NA";
	my $beanNum			=	-1;

	if (int(@annoArr) != int(@colorArr))
	{
		$errmsg = "The number of annotation($annotationStr) is not same with the number of colors($colorStr)!";
		$errmsg = createErrMsg($errmsg);
		
		return ($errmsg,$newAnnoStr,$newColorStr,$beanNum);
	}

	my %annoColorHash;
	undef %annoColorHash;

	for (my $i = 0; $i < int(@annoArr); $i++)
	{
		my $thisAnno  = $annoArr[$i];
		my $thisColor = $colorArr[$i];
	
		if (exists($annoHash{$thisAnno}))
		{
			my $key		= $thisAnno."\t".$thisColor;
			my $value	= length ($thisAnno);

			$annoColorHash{$key} = $value;
		}
	}

	foreach my $key (sort{$annoColorHash{$a}<=>$annoColorHash{$b}} keys %annoColorHash)
	{
		if ($newAnnoStr eq "NA")
		{
			my @tmp = split(/\t/,$key);

			$newAnnoStr		= $tmp[0];
			$newColorStr	= $tmp[1];
			$beanNum			=	1;
		}
		else
		{
			my @tmp = split(/\t/,$key);

			$newAnnoStr		=	$newAnnoStr.",".$tmp[0];
			$newColorStr	=	$newColorStr.",".$tmp[1];
			$beanNum			=	$beanNum + 1;
		}
	}

	return ($errmsg,$newAnnoStr,$newColorStr,$beanNum);
}

sub fallInGroup
{
	my ($hash,$anno,$maf) = @_;

	my $ret = "false";

	my $color = "error";

	if (exists($hash->{$$anno}))
	{
		my @tmp = split(/\t/,$hash->{$$anno});

		my $start = $tmp[0];
		my $end = $tmp[1];

		if (($start < $$maf)&&($$maf <= $end))
		{
			$ret = "true";

			$color = $tmp[2];
		}
	}

	return ($ret,$color);
}

sub hasMinorAllele
{
	my ($txt,$minorAllele) = @_;

	my $ret = "false";

	if (($minorAllele == 0)||($minorAllele == 1))
	{
		my @tmp = split(/\:/,$txt);

		if ($tmp[0] =~ /$minorAllele/)
		{
			$ret = "true";
		}
	}

	return ($ret);
}

sub insertToExonIntron
{
	my ($pos,$arr) = @_;

	for (my $i = 0; $i < int(@{$arr}); $i++)
	{
		if ($arr->[$i][0] eq "exon")
		{
			if (($arr->[$i][1] <= $$pos)&&($$pos <= $arr->[$i][2]))
			{
				if (($arr->[$i][5] == -1)&&($arr->[$i][6] == -1))
				{
					$arr->[$i][5] = $$pos;
					$arr->[$i][6] = $$pos;
				}
				else
				{
					if ($arr->[$i][5] > $$pos)
					{
						$arr->[$i][5] = $$pos;
					}

					if ($arr->[$i][6] < $$pos)
					{
						$arr->[$i][6] = $$pos;
					}
				}

				last;
			}
		}
		elsif ($arr->[$i][0] eq "intron")
		{
			if (($arr->[$i][1] < $$pos)&&($$pos < $arr->[$i][2]))
			{
				if (($arr->[$i][5] == -1)&&($arr->[$i][6] == -1))
				{
					$arr->[$i][5] = $$pos;
					$arr->[$i][6] = $$pos;
				}
				else
				{
					if ($arr->[$i][5] > $$pos)
					{
						$arr->[$i][5] = $$pos;
					}

					if ($arr->[$i][6] < $$pos)
					{
						$arr->[$i][6] = $$pos;
					}
				}

				last;
			}
		}
	}
}

sub transformPhenotype
{
	my ($hash) = @_;

	my $maxPhenotype = "NA";
	my $minPhenotype = "NA";

	while (my ($k,$v) = each %{$hash})
	{
		if ($maxPhenotype eq "NA")
		{
			$maxPhenotype = $k;
		}
		else
		{
			if ($maxPhenotype < $k)
			{
				$maxPhenotype = $k;
			}
		}

		if ($minPhenotype eq "NA")
		{
			$minPhenotype = $k;
		}
		else
		{
			if ($minPhenotype > $k)
			{
				$minPhenotype = $k;
			}
		}
	}

	if ($maxPhenotype == $minPhenotype)
	{
		while (my ($k,$v) = each %{$hash})
		{
			$hash->{$k} = 0.5;
		}
	}
	else
	{
		my $slope = 0.9 / ($maxPhenotype - $minPhenotype);
		my $intercept = 0.05 - 0.9 * $minPhenotype / ($maxPhenotype - $minPhenotype);

		while (my ($k,$v) = each %{$hash})
		{
			$hash->{$k} = $slope * $k + $intercept;
		}
	}
}

sub transformSNPPos
{
	my ($posHash,$posOnRegionHash,$geneStart,$geneEnd,$exonStarts,$exonEnds,$newExonStarts,$newExonEnds,$regions) = @_;

	my $errmsg = "NA";

	my @starts = split(/\,/,$$exonStarts);
	my @ends = split(/\,/,$$exonEnds);
	my @newStarts = split(/\,/,$$newExonStarts);
	my @newEnds = split(/\,/,$$newExonEnds);

	$regions->[0][0] = $$geneStart;		## old region
	$regions->[0][1] = $$geneStart;		## new region
	$regions->[0][2] = "NA";					## old snp position
	$regions->[0][3] = "NA";					## new snp position
	$regions->[0][4] = "NA";					## new snp position on new region

	for (my $i = 0; $i < int(@starts); $i++)
	{
		my $k = int(@{$regions});
		$regions->[$k][0] = $starts[$i];
		$regions->[$k][1] = $newStarts[$i];
		$regions->[$k][2] = "NA";
		$regions->[$k][3] = "NA";
		$regions->[$k][4] = "NA";

		$k = $k + 1;
		$regions->[$k][0] = $ends[$i];
		$regions->[$k][1] = $newEnds[$i];
		$regions->[$k][2] = "NA";
		$regions->[$k][3] = "NA";
		$regions->[$k][4] = "NA";
	}

	my $k = int(@{$regions});
	$regions->[$k][0] = $$geneEnd;
	$regions->[$k][1] = $$geneEnd;
	$regions->[$k][2] = "NA";
	$regions->[$k][3] = "NA";
	$regions->[$k][4] = "NA";

	$k = int(@{$regions});

## put the SNP in regions
	while (my ($pos,$v) = each %{$posHash})
	{
		my $r = "exon";

		for (my $i = 1; $i < $k; $i++)
		{
			my $s = $i - 1;
			my $e = $i;
			
			if ($r eq "exon")
			{
				$r = "intron";
			}
			else
			{
				$r = "exon";
			}

			if ($r eq "exon")
			{
				if (($regions->[$s][0] <= $pos)&&($pos <= $regions->[$e][0]))
				{
					if ($regions->[$s][2] eq "NA")
					{
						$regions->[$s][2] = $pos;
					}
					else
					{
						$regions->[$s][2] = $regions->[$s][2].",".$pos;
					}

					last;
				}
			}
			elsif ($r eq "intron")
			{
				if (($regions->[$s][0] < $pos)&&($pos < $regions->[$e][0]))
				{
					if ($regions->[$s][2] eq "NA")
					{
						$regions->[$s][2] = $pos;
					}
					else
					{
						$regions->[$s][2] = $regions->[$s][2].",".$pos;
					}

					last;
				}
			}
		}
	}

## calculate new snp positions
	for (my $i = 1; $i < int(@{$regions}); $i++)
	{
		my $s = $i - 1;
		my $e = $i;

		my $snps = $regions->[$s][2];

		if ($snps ne "NA")
		{
			my $y1 = $regions->[$s][1];
			my $y2 = $regions->[$e][1];

			my @arr = split(/\,/,$snps);

			my $numOfSNPs = int(@arr);

			@arr = sort {$a <=> $b} @arr;

			my $step = ($y2 - $y1) / ($numOfSNPs + 1);

			$regions->[$s][2] = $arr[0];
			$regions->[$s][3] = $y1 + $step;

			for (my $j = 1; $j < $numOfSNPs; $j++)
			{
				$regions->[$s][2] = $regions->[$s][2].",".$arr[$j];

				my $position = $y1 + $step * ($j + 1);
				$regions->[$s][3] = $regions->[$s][3].",".$position;
			}

## save new snp position to hash
			my @tmp = split(/\,/,$regions->[$s][3]);

			for (my $j = 0; $j < $numOfSNPs; $j++)
			{
				$posHash->{$arr[$j]} = $tmp[$j];
			}
		}
	}

## calculate the new snp position on new region
	for (my $i = 1; $i < int(@{$regions}); $i++)
	{
		my $s = $i - 1;
		my $e = $i;

		if ($regions->[$s][2] ne "NA")
		{
			my $x1 = $regions->[$s][0];
			my $x2 = $regions->[$e][0];

			my $y1 = $regions->[$s][1];
			my $y2 = $regions->[$e][1];

			if ($x1 == $x2)
			{
				my $position = ($y1 + $y2) / 2;

				my @arr = split(/\,/,$regions->[$s][2]);

				for (my $j = 0; $j < int(@arr); $j++)
				{
					$posOnRegionHash->{$arr[$j]} = $position;

					if ($regions->[$s][4] eq "NA")
					{
						$regions->[$s][4] = $position;
					}
					else
					{
						$regions->[$s][4] = $regions->[$s][4].",".$position;
					}
				}
			}
			else
			{
				my @arr = split(/\,/,$regions->[$s][2]);

				my $slope = ($y2 - $y1) / ($x2 - $x1);
				my $intercept = $y1 - $slope * $x1;

				for (my $j = 0; $j < int(@arr); $j++)
				{
					my $position = $slope * $arr[$j] + $intercept;

					$posOnRegionHash->{$arr[$j]} = $position;

					if ($regions->[$s][4] eq "NA")
					{
						$regions->[$s][4] = $position;
					}
					else
					{
						$regions->[$s][4] = $regions->[$s][4].",".$position;
					}
				}
			}
		}
	}

	return ($errmsg);
}

sub transformPhenotype1
{
	my ($hash) = @_;

	my $start = "NA";
	my $end = "NA";

	while (my ($k,$v) = each %{$hash})
	{
		if ($start eq "NA")
		{
			$start = $k;
		}
		else
		{
			if ($start > $k)
			{
				$start = $k;
			}
		}

		if ($end eq "NA")
		{
			$end = $k;
		}
		else
		{
			if ($end < $k)
			{
				$end = $k;
			}
		}
	}

	my $step = $end - $start;

	$step = 0.01 * $step;

	$start = $start - $step;
	$end = $end + $step;

	my $errmsg = "NA";

	if ($start == $end)
	{
		$errmsg = "can't do coordinate transformation with ($start,$end)!";
	}
	else
	{
		my $k = 1 / ($end - $start);
		my $b = $start / ($start - $end);

		while (my ($p,$v) = each %{$hash})
		{
			$v = $k * $p + $b;

			$hash->{$p} = $v;
		}
	}

	return ($errmsg);
}

sub calculateMatchedLine
{
	my ($arr) = @_;

	for (my $i = 0; $i < int(@{$arr}); $i++)
	{
		my $x1 = $arr->[$i][1];
		my $x2 = $arr->[$i][2];
		my $y1 = $arr->[$i][3];
		my $y2 = $arr->[$i][4];
		
		my $p1 = $arr->[$i][5];
		my $p2 = $arr->[$i][6];

		if (($p1 != -1)||($p2 != -1))
		{
			if ($x1 == $x2)
			{
				$arr->[$i][7] = $y1;
				$arr->[$i][8] = $y1;
			}
			else
			{
				my $k = ($y2 - $y1) / ($x2 - $x1);
				my $b = ($x2 * $y1 - $x1 * $y2) / ($x2 - $x1);

				$arr->[$i][7] = $k * $p1 + $b;
				$arr->[$i][8] = $k * $p2 + $b;
			}
		}
	}
}

sub getColors
{
	my ($dir) = @_;
}
1;
