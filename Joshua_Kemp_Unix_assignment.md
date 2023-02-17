#UNIX Assignment

##Data Inspection

### ASCII Characters

I started with a very simple command to check to see if all the characters in the file were ASCII.  I have used data from excel before and it caused me hours of frustration.

```
file *
```
Outcome

* All the input files will be ok to use character wise
* fang\_et\_al_genotypes.txt has very long lines which is not surprising given the hint that we will need to transpose



###Attributes of `snp_position.txt`

```
head snp_position.txt | column -t
```

By inspecting this file I learned that:

* That there are more columns than necessary
* First third and fourth column have the data I am interested in

```
cut -f 1 snp_position.txt | uniq -c
wc -l snp_position.txt 
awk -F "\t" '{print NF; exit}' snp_position.txt
```
This showed that

1. The common column I will join on has no duplicates
2. There are 984 line which implies 983 snps
3. There are 15 total columns which lines up with what I saw previously


###Attributes of `fang_et_al_genotypes.txt`

By inspecting this file with the codes below


````
awk -F "\t" '{print NF; exit}' fang_et_al_genotypes.txt
wc -l fang_et_al_genotypes.txt
cut -f 1-20 fang_et_al_genotypes.txt | head

````

   1. 986 columns in this file 
   2. 2783 lines of data
   3. The first row labels the snps and has similar looking data to the first columnn of the other file
   4. the first 3 columns are meta data including the groups for maize and teosinte that I have to seperate by.  

### Later Inspection

I was inspecting an intermediate file after joining which made me realized that I made a mistake and needed a better workflow
  

```
awk -F "\t" '{print NF; exit}' joined_genotype_snps.txt

2797

wc -l fang_et_al_genotypes.txt           
              
    2783 fang_et_al_genotypes.txt
cut -f 1-16 joined_genotype_snps.txt | column -t | head 

abph1.20  5976  2        27403404   abph1         AB042260  abph1  candidate  8393   10474  1    1     1         ?/?
abph1.22  5978  2        27403892   abph1         AB042260  abph1  candidate  8394   10475  0    0     0         ?/?
ae1.3     6605  5        167889790  ae1           ae1       ae1    candidate  8395   10477  1    1     1         T/T
```

From this I can tell that there are 14 columns of non-genotypic data in the joined table.  The assignment specifies that I am only interested in two. Based on the output of the third command, I am interested in columns 1, 3, and 15-2797.  Given that I do not have the --complement option for cut installed, it is probably easier and safer to remove the extraneous columns from the snp positions file and re-join.  I could use awk to set the fields empty, but I get the feeling that it will leave extra tab delimiters.

While I am at it I suppose joining removes the group option, so to seperate the groups, it is probably best to do that to the genotypes file and then join seperately. 

##Data Processing

### Seperating the Fang File by Species

````
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
````
The comments in this code describe what it is doing.  Since I plan to do this in all in shell script the first thing that I did was create a file to redirect the error stream to. Then I created a directory to work on the seperatioin process in and soft linked the required files in.  I was not used to having to use the . to get the ln command to place the files in the current directory.

To seperate the files first thing was to use grep to grab the first row that has the snp_id info. (rushed though and forgot it the first time). The I used grep to extract the maize groups. options -w for and exact match and -E for the regular expression were used.  >> was used to direct the output to the file already containing the first row.

## Transpose and Sort the Maize and Teosinte Genotypic files

````
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
echo "transposing and sorting genotype files" 2>> ../error_report.err

for Fangfile in *fang_genotypes.txt
do
awk -f transpose.awk ${Fangfile} | sort -f > sandt_${Fangfile} 2>> ../error_report.err
done
#return to top directory
cd ..
````
First steps are the same as before: creating a directory to work in and linking the required files.

Even though there are only two files, I used a for loop so I would not have to type it twice, and I think it is a good habit in case I need to do similar analysis on new files.  This one is pretty easiy though since the code was given to us.  The one thing that I changed was using the -f option since I noticed the ids starting with a were no longer at the top since they were not capitalized.  In the loop, I used variable substituion to create the names for the files.

### Sort the SNP Position File and Remove the Extra Columns

```
#Sort and remove the unnecessary pieces from the snp position file
#also have to use -f option for sort here in order to join
echo "cutting required columns and sorting snp_positons.txt" >> ../error_report.err

cut -f 1,3,4 snp_position.txt | sort -f > sorted_snp_positions.txt 2>> ../error_report.err
```

Used cut to remove to just work with the data that was asked for and the sorted ingnoring capitalization so that it is the same as my genotype files.

### Joining the SNP Positions to the Genotype files

````
## create directory for joining files and link in required files
rm -r genotypefiles
mkdir genotypefiles
cd ./genotypefiles
ln -s ../sort_and_transpose/sandt_* .
ln -s ../sorted_snp_positions.txt .
echo "joining files.." >> ../error_report.err
    
###loop to join maize and teosinte files with the sorted_snp_position file.  SNPid is the common columnfor Genotypes in sandt_*

for Genotypes in sandt*
do
join -1 1 -2 1 -t $'\t' sorted_snp_positions.txt ${Genotypes} > joined_${Genotypes} 2>> ../error_report.err
done
````

First creates the required directory and links the appropriate files.  Then adds snp id position information using join.  column on in file 1 and 2 is the common column, -t  \$'\t' indicates that the files are tab delimited.

### Replace ? with - for missing data

````
## create versions of these two files with ? notation replaced with -
echo "replacing questionmarks with hyphens" >> ../error_report.err
#loop with sed to replace question marks good thing there are none in the header or snp_ids

for GenoSNP in joined*
do
sed 's/?/-/g' ${GenoSNP} > hyphen_${GenoSNP} 2>> ../error_report.err
done

#return to main working directory
cd ..
````

This script takes the genotype files and creates a new file where every question mark has been replaced with a hyphen.  The /g is the important part to make sure that it replaces every instance of ?.

### Create directory and a Shell Script for Seperating files by Chromosme and Sorting by Position

````
#create new directory for seperating chr and sorting by position
rm -r chr_seperate_and_sort
mkdir chr_seperate_and_sort
cd ./chr_seperate_and_sort
#soft link required files
ln -s ../genotypefiles/*joined_* .
#create directory to store output files
rm -r ../output
mkdir ../output


## Create a executable bash script to seperate our files by chromosome call seperate_by_chr.sh
##seperate_by_chr.sh assumes chr information is in column 2 and in numberic format and that there are 10 chromosomes and that SNP positon is in the 3rd column

cat << 'EOF' > seperate_by_chr_and_sort_position.sh
#!/bin/bash
for CHR in {1..10} multiple unknown
do
awk -v CHR=${CHR} '$2==CHR {print $0}' $1 | sort -k3,3n > ../output/chr_${CHR}_$1
done
EOF
````

First half simply is creating another directory to use as a working space for this step.

The second half of code creates a shell script I can run to seperate and sort our files.  The 'cat << 'EOF' > seperate\_by\_chr\_and\_sort\_position.sh' is a here document iused to redirect input into a shell script, which in this case is called 'seperate\_by\_chr\_and\_sort\_position.sh'.  EOF is the delimiter used and in this command it will not interperet anything untill it sees EOF again.  All the while we are directed the non-interpered output to a file that will become our script. 

In the for loop we use the expansion {1,..10} since we have 10 chromosomes and add the arguments missing and unknown so that it represents all the values present in the chromosome column of our data.  Then becuase awk is its own language in a way we have to use the -v option, which stands for variable, to be able to define and use our loop variable within awk.  $1 represents the first argument entered after the shell script command.  Which in this case I intend to be a genotype file needing to be split.  The code searches column 2 (chromome#) of the input file to match the chromosome the loop is on and prints all matching lines into the pipe.

The pipe passes that data to sort which sorts column 3 (k3) representing position data, and sorts it numerically since the option ,3n specificies that column 3 is numeric.  The sorted data is then passed to a new file in the directory output with a name derived from the chromosome we are sorting by, and the name of the starting genotype file.

### Running the Shell Script "seperate\_by\_chr\_and\_sort\_position.sh"

````
##run files through the seperation and sorting
echo "starting joining process" >> ../error_report.err
for GenoSNPfiles in *joined_*
do
bash seperate_by_chr_and_sort_position.sh ${GenoSNPfiles} 2>> ../error_report.err
done
````

If our shell script was written well all we need to do is use bash to call the script and enter our genotype files into it using a loop.

### Remove Extra Unknown Chr and Missing Chr Files

````
#move to output folder
cd ../output/
echo "starting unknown and multiple removal" >> ../error_report.err
##Remove extra unknown and missing positon files that were not asked for
rm chr_{unknown,multiple}_hyphen* 2>> ../error_report.err
````
The script creates seperates both the hypenated and questionmark versions of the genotype files.  Since the assignment only asks for one or the other this script removes the hyphenated missing and unknown files. 12*4-4=44 files.

Inspection of the files using head tail and sort -c confirm that the files seem to contain the correct infomation and are correctly sorted.

### Renaming Files


````
## clean up the names so that they are in a format that is easily sorted
    for file in *
    do
    mv "$file" "${file/_hyphen_joined_sandt_/_hyphen_}" 2>/dev/null
    mv "$file" "${file/_joined_sandt_/_questionmark_}" 2>/dev/null
    done
    for file in *
    do
    mv "$file" "${file/*hyphen*/hyphen_${file}}" 2>/dev/null
    mv "$file" "${file/*questionmark*/questionmark_${file}}" 2>/dev/null
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
````

This is not a great script, but it moves elements of the name around so that they are in a format that is simpler, makes more sense and is easier to sort.
    
>Before:`chr_1_hyphen_joined_sandt_maize_fang_genotypes.txt`


>After:`maize_hyphen_chr_1_SNPS.txt`





