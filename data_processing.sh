#!/bin/bash

## Create error report file
rm error_report.err
touch error_report.err
## Seperate Genotypes file into the maize and teosinte groups
rm -r seperate_maize_and_teosinte
mkdir seperate_maize_and_teosinte
cd ./seperate_maize_and_teosinte
ln -s ../fang_et_al_genotypes.txt .

echo "seperating genotypes file into maize and teosinte each with their own header" >> ../error_report.err
#grab the header that I want and need to match
grep "^Sample_ID" fang_et_al_genotypes.txt > maize_fang_genotypes.txt 2>> ../error_report.err
#grab the maize genotypic data and add it to the file
grep -w -E "(ZMMIL|ZMMLR|ZMMMR)" fang_et_al_genotypes.txt >> maize_fang_genotypes.txt 2>> ../error_report.err
# same header for the teosinte
grep "^Sample_ID" fang_et_al_genotypes.txt > teosinte_fang_genotypes.txt 2>> ../error_report.err
#grep out the teosinte genotypic data and add it to the file with the header
grep -w -E "(ZMPBA|ZMPIL|ZMPJA)" fang_et_al_genotypes.txt >> teosinte_fang_genotypes.txt 2>> ../error_report.err
cd ..


## transpose and sort fang files

##create and empty directory
rm -r sort_and_transpose
mkdir sort_and_transpose
## move into the directory
cd ./sort_and_transpose
#link previous outputfiles
ln -s ../seperate_maize_and_teosinte/*fang_genotypes.txt .
ln -s ../transpose.awk .

#loop to traspose and sort by snp id our fang genotype files for Maize and teosinte
#using the -f option becuase I think this file looks better when case is ignored
echo "transposing and sorting genotype files" >> ../error_report.err

for Fangfile in *fang_genotypes.txt
do
awk -f transpose.awk ${Fangfile} | sort -f > sandt_${Fangfile} 2>> ../error_report.err
done
#return to top directory
cd ..


#Sort and remove the unnecessary pieces from the snp position file
#also have to use -f option for sort here in order to join
echo "cutting required columns and sorting snp_positons.txt" >> ../error_report.err

cut -f 1,3,4 snp_position.txt | sort -f > sorted_snp_positions.txt 2>> ../error_report.err



## create directory for joining files and link in required files
rm -r genotypefiles
mkdir genotypefiles
cd ./genotypefiles
ln -s ../sort_and_transpose/sandt_* .
ln -s ../sorted_snp_positions.txt .
    echo "joining files.." >> ../error_report.err
    
## loop to join maize and teosinte files with the sorted_snp_position file.  SNPid is the common columnfor Genotypes in sandt_*

for Genotypes in sandt*
do
join -1 1 -2 1 -t $'\t' sorted_snp_positions.txt ${Genotypes} > joined_${Genotypes} 2>> ../error_report.err
done

## Place unknown and multiple positions into their own files and then remove them from the originals
for Joined in joined_*
do
awk '$3 ~ /multiple/ {print $0}' ${Joined} > multiple${Joined}
awk '$3 ~ /unknown/ {print $0}' ${Joined} > unknown${Joined}
awk '$3 !~ /unknown/ && $3 !~ /multiple/ {print $0}' ${Joined} > questionmark_${Joined}
done

## create versions of these two files with ? notation replaced with -

echo "replacing questionmarks with hyphens" >> ../error_report.err
#loop with sed to replace question marks good thing there are none in the header or snp_ids

for GenoSNP in questionmark_joined*
do
sed 's/?/-/g' ${GenoSNP} > "${GenoSNP/questionmark/hyphen}" 2>> ../error_report.err
done

#return to main working directory
cd ..


#create new directory for seperating chr and sorting by position
rm -r chr_seperate_and_sort
mkdir chr_seperate_and_sort
cd ./chr_seperate_and_sort
#soft link required files
ln -s ../genotypefiles/*_joined_* .
#create directory to store output files
rm -r ../output
mkdir ../output


## Create a executable bash script to seperate our files by chromosome call seperate_by_chr.sh
##seperate_by_chr.sh assumes chr information is in column 2 and in numberic format and that there are 10 chromosomes and that SNP positon is in the 3rd column

cat << 'EOF' > seperate_by_chr_and_sort_position.sh
#!/bin/bash
for CHR in {1..10}
do
awk -v CHR=${CHR} '$2==CHR {print $0}' $1 | sort -k3,3n > ../output/chr_${CHR}_$1
done
EOF

## Create a executable bash script to seperate our files by chromosome call seperate_by_chr.sh then sort in reverse
##seperate_by_chr.sh assumes chr information is in column 2 and in numberic format and that there are 10 chromosomes and that SNP positon is in the 3rd column

cat << 'EOF' > seperate_by_chr_and_sort_position_reverse.sh
#!/bin/bash
for CHR in {1..10}
do
awk -v CHR=${CHR} '$2==CHR {print $0}' $1 | sort -k3,3nr > ../output/chr_${CHR}_$1
done
EOF



##run questionmark files through the seperation and sorting
echo "starting joining process" >> ../error_report.err
for GenoSNPfiles in questionmark_joined_*
do
bash seperate_by_chr_and_sort_position.sh ${GenoSNPfiles} 2>> ../error_report.err
done

##run hyphen files through seperation and reverse sorting
for GenoSNPfiles in hyphen_joined_*
do
bash seperate_by_chr_and_sort_position_reverse.sh ${GenoSNPfiles} 2>> ../error_report.err
done


#move to output folder
cd ../output/
echo "start adding unknown and multiple" >> ../error_report.err
##Remove extra unknown and missing positon files that were not asked for
cp ../genotypefiles/multiple* .
cp ../genotypefiles/unknown* .


## clean up the names so that they are in a format that is easily sorted
    for file in *
    do
    mv "$file" "${file/_hyphen_joined_sandt_/_hyphen_}" 2>/dev/null
    mv "$file" "${file/questionmark_joined_sandt_/_questionmark_}" 2>/dev/null
    done
    for file in *
    do
    mv "$file" "${file/*hyphen*/hyphen_${file}}" 2>/dev/null
    mv "$file" "${file/*questionmark*/questionmark${file}}" 2>/dev/null
    done
    for file in *
    do
    mv "$file" "${file/_hyphen_/_}" 2>/dev/null
    mv "$file" "${file/_questionmark_/_}" 2>/dev/null
    done
    for file in *
    do
    mv "$file" "${file/*maize*/maize_${file}}" 2>/dev/null
    mv "$file" "${file/*teosinte*/teosinte_${file}}" 2>/dev/null
    done
    for file in *
    do
    mv "$file" "${file/_maize_fang_genotypes/_SNPS}" 2>/dev/null
    mv "$file" "${file/_teosinte_fang_genotypes/_SNPS}" 2>/dev/null
    done
##done should have all the necessary files

exit
