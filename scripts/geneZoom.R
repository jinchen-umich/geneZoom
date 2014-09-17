#! /usr/bin/Rscript --vanilla
# --default-packages=utils,stats,lattice,grid,getopts
# need to check if the line above works on the web deployment machine.

# Copyright 2014 Jin Chen,Cristen Willer
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

suppressPackageStartupMessages({
	require(grid);
  require(beanplot);
  require(gridBase);
});


#############################################################
#
# process argument list, splitting the key=value pairs
#
argv <- function(){
	args <- commandArgs(TRUE);
	newl <- list();

	for ( i in 1:length(args) ) {
		keyval <- strsplit(args[[i]],"=")[[1]];
		key <- keyval[1];
		val <- keyval[2];
		newl[[ key ]] <- val;
	}

	return(newl);
}

################################################################################
#
# like modifyList, but works when names of val are unique prefixes of names of x
#
ConformList <- function(x,names,case.sensitive=FALSE,message=FALSE) {
	own.ind <- 0;
	for (name in names(x)) {
		own.ind <- own.ind + 1;
		
		if (case.sensitive) {
			match.ind <- pmatch( name, names );
		} else {
			match.ind <- pmatch( toupper(name), toupper(names) );
		}

		if (! is.na(match.ind)) {
			names(x)[own.ind] <- names[match.ind];
		} else {
			if (! is.null(message) ) {
				message(paste("No unique match for ",name,"=",x[[own.ind]],sep=""));
			}
		}
	}

	return(x);
}

#############################################################
#
# Create geneZoom output
#
# NB: *** passing in entire args list ***
#
gzplot <- function(geneRegion,scatter,allData,otherData,matchedLines,args){
	#grid.newpage();
	plot.new();

	
## calculate the width of beanplot and scatter plot
	scatterPlotWidth <- 10 - as.numeric(args[['beanPlotNum']]);
	beanPlotWidth <- as.numeric(args[['beanPlotNum']]);

## This is the main viewport. It is split to 3 rows and 3 columns
#### Rows
###### The first row is 2 line height. The main title is on this area.
###### The third row is also 2 line height. The xlab is on this area.
###### The other part is the second row. All plots are on this row.
#### Columns
###### The first column is 2 line width. The y-lab is on this area.
###### The second is also 2 line width. The y-axis is on this area.
###### The other part is the third column. All plots are on this column.	
#	vp <- viewport(x=0.5,y=0.5,width=0.95,height=0.95,layout=grid.layout(3,3,heights=unit(c(2,1,2),c("lines","null","lines")),widths=unit(c(2,2,1),c("lines","lines","null"))));
	vp <- viewport(x=0.5,y=0.5,width=0.95,height=0.95,layout=grid.layout(3,3,heights=unit(c(2,1,2),c("lines","null","lines")),widths=unit(c(3,3,1),c("lines","lines","null"))));

## Enter the maim page viewport. We will not go out untill everything is done 	
	pushViewport(vp);
	#grid.rect(gp=gpar(lty="dashed"));

#### Enter the title viewpot. When main title is displayed, we will go back to the main viewport
	pushViewport(viewport(layout.pos.col=3,layout.pos.row=1));
	#grid.rect(gp=gpar(lty="dashed"));
	grid.text(args[['title']],gp=gpar(cex=args[['titleCex']]));
	popViewport();

#### Enter the y-lab viewport. When y-lab is displayed, we will go back to the main viewport
	pushViewport(viewport(layout.pos.col=1,layout.pos.row=2));
	#grid.rect(gp=gpar(lty="dashed"));
	grid.text(args[['ylab']],,gp=gpar(cex=args[['ylabCex']]),rot=90);
	popViewport();

#### Enter the x-lab viewport. When x-lab is displayed, we will go back to the main viewport
	pushViewport(viewport(layout.pos.col=3,layout.pos.row=3));
	#grid.rect(gp=gpar(lty="dashed"));
	grid.text(args[['xlab']],gp=gpar(cex=args[['xlabCex']]));
	popViewport();

#### Enter plot viewport. When all plots are displayed, we will go back to the main viewport
	pushViewport(viewport(layout.pos.col=3,layout.pos.row=2));
	#grid.rect(gp=gpar(lty="dashed"));

###### The plot viewport are split to 3 rows and 2 columns
######## Rows
########## The second row is 2.5 line height. The matched lines are in this region.
########## The third row is 0.5 line height. The exons are shown in this region.
########## The other part is the first row. The scatter plot and bean plot are in this region. 
######## Columns
########## The first column is (10 - beanPlotNum)/10 width. The scatter plot is in thie region.
########## The second column is beanPlotNum/10 width. The bean plots are in this region.
	vpPage <- viewport(layout=grid.layout(3,2,widths=unit(c(scatterPlotWidth,beanPlotWidth),c("null","null")),heights=unit(c(1,2.5,0.5),c("null","lines","lines"))));
	pushViewport(vpPage);

######## Draw scatter plot
########## Prepare some paramters of scatter plot, such x range, y range
	phenotypeMax <- max(scatter$phenotype);
	phenotypeMin <- min(scatter$phenotype);
	scatterXRange <- c(geneRegion$geneStart,geneRegion$geneEnd);
	scatterYRange <- c(phenotypeMin - 0.05 * (phenotypeMax - phenotypeMin),phenotypeMax + 0.05 * (phenotypeMax - phenotypeMin));
	meanOfPhenotype <- mean(allData$phenotype);
	sdOfPhenotype <- sd(allData$phenotype);
	upSD <- meanOfPhenotype + sdOfPhenotype;
	downSD <- meanOfPhenotype - sdOfPhenotype;
########## Enter scatter plot viewport. When the scatter plot is draw, we will go back to the plot viewport.
	pushViewport(viewport(layout.pos.col=1,layout.pos.row=1,xscale=scatterXRange, yscale=scatterYRange));
	grid.rect(gp=gpar(lty="solid",col="black"));
########## Draw scatter plot's y-axis
	#grid.yaxis(at=seq(scatterYRange[1],scatterYRange[2],100),gp=gpar(cex=args[['scatterYAxisCex']]));
	grid.yaxis(gp=gpar(cex=args[['scatterYAxisCex']]));
########## Draw scatter points
	for (i in 1:length(scatter$new_pos))
	{
		grid.points(scatter$new_pos[i], scatter$phenotype[i],size=unit(2, "mm"),gp=gpar(col=as.character(scatter$color[i])));
	}
########## Draw mean of phenotype line
	grid.lines(x=unit(c(geneRegion$geneStart,geneRegion$geneEnd),"native"),y=unit(c(meanOfPhenotype,meanOfPhenotype),"native"),gp=gpar(col=args[['phenotyeMeanLineColor']],lty=args[['phenotyeMeanLineType']]));
########## Draw sd of phenotype lines
	grid.lines(x=unit(c(geneRegion$geneStart,geneRegion$geneEnd),"native"),y=unit(c(upSD,upSD),"native"),gp=gpar(col=args[['phenotyeSDLineColor']],lty=args[['phenotyeSDLineType']]));
	grid.lines(x=unit(c(geneRegion$geneStart,geneRegion$geneEnd),"native"),y=unit(c(downSD,downSD),"native"),gp=gpar(col=args[['phenotyeSDLineColor']],lty=args[['phenotyeSDLineType']]));
########## Draw lables
	#grid.text("chr2:21233706",x=unit(21238243.420905,"native"),y=unit(75,"native"),rot=90,just="left");
	#grid.text("chr2:21260985",x=unit(21263778.5975993,"native"),y=unit(70,"native"),rot=45,just="left");
	#grid.text("chr2:21249659",x=unit(21255224.1989589,"native"),y=unit(70,"native"),rot=0);
########## Go back to plot viewport
	popViewport();


######## Draw matched lines
########## Enter matched lines viewport. When the matched lines are draw, we will go back to the plot viewport.
	pushViewport(viewport(layout.pos.col=1,layout.pos.row=2,xscale=scatterXRange, yscale=c(0,1)));
	#grid.rect(gp=gpar(lty="solid",col="black"));
########## Draw matched lines
	for (i in 1:length(scatter$new_pos))
	{
		#grid.lines(x=unit(c(as.numeric(scatter$new_pos[i]),as.numeric(scatter$pos_on_region[i])),"native"),y=unit(c(1,-0.1),"native"),gp=gpar(col=cols[annotationColors[scatter$annotation[i]]]));
		grid.lines(x=unit(c(as.numeric(scatter$new_pos[i]),as.numeric(scatter$pos_on_region[i])),"native"),y=unit(c(1,-0.1),"native"),gp=gpar(col=as.character(scatter$color[i])));
	}
########## Go back to plot viewport
	popViewport();


######## Draw exon regions
########## Calculate exon regions
	starts<-strsplit(as.character(geneRegion$newExonStarts),",")[[1]];
	ends<-strsplit(as.character(geneRegion$newExonEnds),",")[[1]];
########## Enter the exon region viewport. When the exon regions are draw, we will go back to the plot viewport.
	pushViewport(viewport(layout.pos.col=1,layout.pos.row=3,xscale=scatterXRange, yscale=c(0,1)));
	#grid.rect(gp=gpar(lty="solid",col="black"));
########## Draw middle line for exon regions
	grid.lines(x=unit(c(scatterXRange[1],scatterXRange[2]),"native"),y=unit(c(0.5,0.5),"native"),gp=gpar(col=args[['exonRegionColor']]));
########## Draw exon regions
	for (i in 1:length(starts))
	{
		x1 <- as.numeric(starts[i]);
		x2 <- as.numeric(ends[i]);

		x3 <- (x1 + x2) / 2;
		w <- x2 - x1;
		grid.rect(x=unit(x3,"native"), y=unit(0.5,"native"), width=unit(w,"native"), height=unit(0.9,"native"), gp=gpar(fill=args[['exonRegionColor']]));
	}
########## Go back to plot viewport
	popViewport();

######## Draw beanplot
########## Prepare paremeters
	annotations <- strsplit(as.character(args[['annotations']]),",")[[1]];
	colors <- strsplit(as.character(args[['annotationColors']]),",")[[1]];
	beanPlotXAxisLabelAngle <- as.numeric(args[['beanPlotXAxisLabelAngle']]);
	beanPlotXAxisLableCex <- as.numeric(args[['beanPlotXAxisLableCex']]);
	beanPlotXAxisLablePos1 <- as.numeric(args[['beanPlotXAxisLablePos1']]);
	beanPlotXAxisLablePos2 <- as.numeric(args[['beanPlotXAxisLablePos2']]);
########## Enter beanplot viewport. When the beanplot is draw, we will go back to the plot viewport.
	pushViewport(viewport(layout.pos.col=2,layout.pos.row=1));
	grid.rect(gp=gpar(lty="solid",col="black"));
	par(plt=gridPLT())
	par(new=TRUE)

	if (length(annotations) == 1)
	{
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);
	
		beanplot(beanData1,otherData$phenotype,col=list(col1,"black"),names=list(as.character(annotations[1]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,2,by=1),labels=FALSE);
		#text(x=seq(1,2,by=1), labels=list(as.character(annotations[1]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,2,by=1)),text=c(as.character(annotations[1]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2));
	} else if (length(annotations) == 2) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);
		
		#beanplot(beanData1,beanData2,otherData$phenotype,col=list(col1,col2,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",cex.axis=0.5);
		beanplot(beanData1,beanData2,otherData$phenotype,col=list(col1,col2,"black"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",yaxt="n",xaxt="n");
		axis(1,at=seq(1,3,by=1),labels=FALSE);
		#text(x=seq(1,3,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,3,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1));
	} else if (length(annotations) == 3) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanplot(beanData1,beanData2,beanData3,otherData$phenotype,col=list(col1,col2,col3,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,4,by=1),labels=FALSE);
		#text(x=seq(1,4,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,4,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2));
	} else if (length(annotations) == 4) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanData4 <- scatter$phenotype[(scatter$annotation == as.character(annotations[4]))];
		col4 <- as.character(colors[4]);

		beanplot(beanData1,beanData2,beanData3,beanData4,otherData$phenotype,col=list(col1,col2,col3,col4,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,5,by=1),labels=FALSE);
		#text(x=seq(1,5,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,5,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1));
	} else if (length(annotations) == 5) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanData4 <- scatter$phenotype[(scatter$annotation == as.character(annotations[4]))];
		col4 <- as.character(colors[4]);

		beanData5 <- scatter$phenotype[(scatter$annotation == as.character(annotations[5]))];
		col5 <- as.character(colors[5]);

		beanplot(beanData1,beanData2,beanData3,beanData4,beanData5,otherData$phenotype,col=list(col1,col2,col3,col4,col5,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,6,by=1),labels=FALSE);
		#text(x=seq(1,6,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,6,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2));
	} else if (length(annotations) == 6) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanData4 <- scatter$phenotype[(scatter$annotation == as.character(annotations[4]))];
		col4 <- as.character(colors[4]);

		beanData5 <- scatter$phenotype[(scatter$annotation == as.character(annotations[5]))];
		col5 <- as.character(colors[5]);

		beanData6 <- scatter$phenotype[(scatter$annotation == as.character(annotations[6]))];
		col6 <- as.character(colors[6]);

		beanplot(beanData1,beanData2,beanData3,beanData4,beanData5,beanData6,otherData$phenotype,col=list(col1,col2,col3,col4,col5,col6,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,7,by=1),labels=FALSE);
		#text(x=seq(1,7,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,7,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1));
	} else if (length(annotations) == 7) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanData4 <- scatter$phenotype[(scatter$annotation == as.character(annotations[4]))];
		col4 <- as.character(colors[4]);

		beanData5 <- scatter$phenotype[(scatter$annotation == as.character(annotations[5]))];
		col5 <- as.character(colors[5]);

		beanData6 <- scatter$phenotype[(scatter$annotation == as.character(annotations[6]))];
		col6 <- as.character(colors[6]);

		beanData7 <- scatter$phenotype[(scatter$annotation == as.character(annotations[7]))];
		col7 <- as.character(colors[7]);

		beanplot(beanData1,beanData2,beanData3,beanData4,beanData5,beanData6,beanData7,otherData$phenotype,col=list(col1,col2,col3,col4,col5,col6,col7,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,8,by=1),labels=FALSE);
		#text(x=seq(1,8,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,8,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2));
	} else if (length(annotations) == 8) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanData4 <- scatter$phenotype[(scatter$annotation == as.character(annotations[4]))];
		col4 <- as.character(colors[4]);

		beanData5 <- scatter$phenotype[(scatter$annotation == as.character(annotations[5]))];
		col5 <- as.character(colors[5]);

		beanData6 <- scatter$phenotype[(scatter$annotation == as.character(annotations[6]))];
		col6 <- as.character(colors[6]);

		beanData7 <- scatter$phenotype[(scatter$annotation == as.character(annotations[7]))];
		col7 <- as.character(colors[7]);

		beanData8 <- scatter$phenotype[(scatter$annotation == as.character(annotations[8]))];
		col8 <- as.character(colors[8]);

		beanplot(beanData1,beanData2,beanData3,beanData4,beanData5,beanData6,beanData7,beanData8,otherData$phenotype,col=list(col1,col2,col3,col4,col5,col6,col7,col8,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,9,by=1),labels=FALSE);
		#text(x=seq(1,9,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,9,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1));
	} else if (length(annotations) == 9) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanData4 <- scatter$phenotype[(scatter$annotation == as.character(annotations[4]))];
		col4 <- as.character(colors[4]);

		beanData5 <- scatter$phenotype[(scatter$annotation == as.character(annotations[5]))];
		col5 <- as.character(colors[5]);

		beanData6 <- scatter$phenotype[(scatter$annotation == as.character(annotations[6]))];
		col6 <- as.character(colors[6]);

		beanData7 <- scatter$phenotype[(scatter$annotation == as.character(annotations[7]))];
		col7 <- as.character(colors[7]);

		beanData8 <- scatter$phenotype[(scatter$annotation == as.character(annotations[8]))];
		col8 <- as.character(colors[8]);

		beanData9 <- scatter$phenotype[(scatter$annotation == as.character(annotations[9]))];
		col9 <- as.character(colors[9]);

		beanplot(beanData1,beanData2,beanData3,beanData4,beanData5,beanData6,beanData7,beanData8,beanData9,otherData$phenotype,col=list(col1,col2,col3,col4,col5,col6,col7,col8,col9,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),as.character(annotations[9]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,10,by=1),labels=FALSE);
		#text(x=seq(1,10,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),as.character(annotations[9]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,10,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),as.character(annotations[9]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2));
	} else if (length(annotations) == 10) {
		beanData1 <- scatter$phenotype[(scatter$annotation == as.character(annotations[1]))];
		col1 <- as.character(colors[1]);

		beanData2 <- scatter$phenotype[(scatter$annotation == as.character(annotations[2]))];
		col2 <- as.character(colors[2]);

		beanData3 <- scatter$phenotype[(scatter$annotation == as.character(annotations[3]))];
		col3 <- as.character(colors[3]);

		beanData4 <- scatter$phenotype[(scatter$annotation == as.character(annotations[4]))];
		col4 <- as.character(colors[4]);

		beanData5 <- scatter$phenotype[(scatter$annotation == as.character(annotations[5]))];
		col5 <- as.character(colors[5]);

		beanData6 <- scatter$phenotype[(scatter$annotation == as.character(annotations[6]))];
		col6 <- as.character(colors[6]);

		beanData7 <- scatter$phenotype[(scatter$annotation == as.character(annotations[7]))];
		col7 <- as.character(colors[7]);

		beanData8 <- scatter$phenotype[(scatter$annotation == as.character(annotations[8]))];
		col8 <- as.character(colors[8]);

		beanData9 <- scatter$phenotype[(scatter$annotation == as.character(annotations[9]))];
		col9 <- as.character(colors[9]);

		beanData10 <- scatter$phenotype[(scatter$annotation == as.character(annotations[10]))];
		col10 <- as.character(colors[10]);

		beanplot(beanData1,beanData2,beanData3,beanData4,beanData5,beanData6,beanData7,beanData8,beanData9,beanData10,otherData$phenotype,col=list(col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,"black"),names=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),as.character(annotations[9]),as.character(annotations[9]),as.character(annotations[10]),"other"),bw="nrd0",what=c(1,1,1,0),ylim=scatterYRange,log="",yaxs="i",yaxt="n",xaxt="n");
		axis(1,at=seq(1,11,by=1),labels=FALSE);
		#text(x=seq(1,11,by=1), labels=list(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),as.character(annotations[9]),as.character(annotations[10]),"other"),srt=beanPlotXAxisLabelAngle,pos=2,xpd=TRUE,cex=beanPlotXAxisLableCex);
		mtext(side=1,at=c(seq(1,11,by=1)),text=c(as.character(annotations[1]),as.character(annotations[2]),as.character(annotations[3]),as.character(annotations[4]),as.character(annotations[5]),as.character(annotations[6]),as.character(annotations[7]),as.character(annotations[8]),as.character(annotations[9]),as.character(annotations[10]),"other"),cex=beanPlotXAxisLableCex,line=c(beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1,beanPlotXAxisLablePos2,beanPlotXAxisLablePos1));
	}
########## Go back to plot viewport
	popViewport();
######## Go back to main viewport
	popViewport();
	popViewport();
	popViewport();
}


	
#################################################################################
#                                                                               #
#                         MAIN PROGRAM BEGINS HERE                              #
#                                                                               #
#################################################################################

default.args <- list(
	geneRegionFile					=	NULL,                         
	annotationFlag					=	NULL,                 
	scatterData							=	NULL,                       
	allData									=	NULL,
	otherData								=	NULL,
	matchedLines						=	NULL,
	dir											= NULL,
	format									=	'pdf',
	geneName								=	NULL,
	title										=	NULL,
	xlab										=	NULL,
	ylab										=	NULL,
	titleCex								=	1,
	xlabCex									=	1,
	ylabCex									=	1,
	scatterYAxisCex					=	0.8,
	phenotyeMeanLineColor		=	'blue',
	phenotyeMeanLineType		=	'solid',
	phenotyeSDLineColor			=	'blue',
	phenotyeSDLineType			=	'dashed',
	exonRegionColor					=	'blue',
	annotations							=	NULL,
	annotationColors				=	NULL,
	beanPlotNum							=	0,
	beanPlotXAxisLabelAngle	=	45,
	beanPlotXAxisLableCex		=	0.8,
	beanPlotXAxisLablePos1	=	0.5,
	beanPlotXAxisLablePos2	=	1.5,
	outFile									=	NULL,
	width										=	14,
	height									=	10
)

args <- ConformList(argv(),names(default.args),message=TRUE)

################################################################################
#
# read data
#

#
# read gene region data or reload all.
#

#args[['phenotyeMeanLineColor']]	=	'blue';
#args[['phenotyeMeanLineType']]	=	'solid';
#args[['phenotyeSDLineColor']]	=	'blue';
#args[['phenotyeSDLineType']]		=	'dashed';
#args[['exonRegionColor']]		= 	'blue'
#args[['annotations']]			=	'splicing,nonsynonymous'
#args[['annotationColors']]		=	'red,blue';
#args[['beanPlotXAxisLabelAngle']]	=	45;
#args[['beanPlotXAxisLableCex']]	=	0.5;
#args[['beanPlotXAxisLablePos1']]	=	0.5;
#args[['beanPlotXAxisLablePos2']]	=	1.5;
#args[['titleCex']]	=	2;
#args[['xlabCex']]	=	2;
#args[['ylabCex']]	=	2;

if ( file.exists( args[['geneRegionFile']]) ) {
	geneRegion <- read.table(args[['geneRegionFile']],header=T,sep="\t");
} else {
	stop(paste('No such file: ', args[['geneRegionFile']]));
}

if ( file.exists( args[['annotationFlag']]) ) {
	flag <- read.table(args[['annotationFlag']],header=T,sep="\t")
} else {
	stop(paste('No such file: ', args[['annotationFlag']]));
}

if ( file.exists( args[['scatterData']]) ) {
	scatter <- read.table(args[['scatterData']],header=T,sep="\t");
} else {
	stop(paste('No such file: ', args[['scatterData']]));
}

if ( file.exists( args[['allData']]) ) {
	allData <- read.table(args[['allData']],header=T,sep="\t");
} else {
	stop(paste('No such file: ', args[['allData']]));
}

if ( file.exists( args[['otherData']]) ) {
	otherData <- read.table(args[['otherData']],header=T,sep="\t");
} else {
	stop(paste('No such file: ', args[['otherData']]));
}

if ( file.exists( args[['matchedLines']]) ) {
	matchedLines <- read.table(args[['matchedLines']],header=F,sep="\t");
} else {
	stop(paste('No such file: ', args[['matchedLines']]));
}


#
# deal with some parameters
#

if (is.null(args[['geneName']])||(args[['geneName']] == "NULL"))
{
	args[['title']] <- "Gene variants identified";
} else {
	args[['title']] <- paste(args[['geneName']],"variants identified");
}

if((is.null(args[['xlab']]))||(args[['xlab']] == "NULL"))
{
	if ((is.null(args[['geneName']]))||(args[['geneName']] == "NULL"))
	{
		args[['xlab']] <- "exons";
	} else {
		args[['xlab']] <- paste(args[['geneName']],"exons",sep=" ");
	}
} 

if ((is.null(args[['ylab']]))||(args[['ylab']] == "NULL"))
{
	args[['ylab']] <- "Phenotype";
}

if (is.null(args[['format']]))
{
	args[['format']] <- 'pdf';
} else {
	args[['format']] <- tolower(args[['format']]);

	if (('pdf' != args[['format']])&('jpg' != args[['format']])&('png' != args[['format']])&('tiff' != args[['format']]))
	{
		stop(paste('The format of output file (',args[['format']],') is wrong!'));
	}
}

if (is.null(args[['dir']]))
{
	stop(paste('The directory of result (',args[['dir']],') doesn\'t define!'));
}

#
# check the number of annotations and nunmber of colors same
#

if ('pdf' %in% args[['format']]){
	args[['outFile']] <- paste(args[['dir']],args[['geneName']],".pdf",sep="");

	pdf(file=args[['outFile']],width=as.numeric(args[['width']]),height=as.numeric(args[['height']]));
	gzplot(geneRegion,scatter,allData,otherData,matchedLines,args=args);
	dev.off();
} else if ('png' %in% args[['format']]){
	args[['outFile']] <- paste(args[['dir']],args[['geneName']],".png",sep='');

	png(file=args[['outFile']],width=as.numeric(args[['width']])*100,height=as.numeric(args[['height']])*100);
	gzplot(geneRegion,scatter,allData,otherData,matchedLines,args=args);
	dev.off();
} else if ('tiff' %in% args[['format']]){
	args[['outFile']] <- paste(args[['dir']],args[['geneName']],".tiff",sep='');

	tiff(file=args[['outFile']],width=as.numeric(args[['width']])*100,height=as.numeric(args[['height']])*100);
	gzplot(geneRegion,scatter,allData,otherData,matchedLines,args=args);
	dev.off();
}
 
