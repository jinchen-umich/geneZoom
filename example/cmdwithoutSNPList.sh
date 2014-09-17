DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

perl $DIR/../scripts/geneZoom.pl --vcf $DIR/vcf.vcf.gz --gene PCSK9 --phenotypeFile $DIR/phenotype.file --sampleFieldName sample --phenotypeFieldName phenotype --phenotypeDelim tab  --flags "Missense:0:0.01:red,nonsense:0.05:0.1:green,splicing:blue,readthrough:yellow" --outDIR $DIR/outDIR --format png --titleCex 1.5 --xlabCex 2 --ylabCex 2 --beanPlotXAxisLableCex 1.5 --beanPlotXAxisLablePos2 3  --beanPlotXAxisLablePos1 1.5
