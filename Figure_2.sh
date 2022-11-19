#! /bin/bash

set -e

###### SMEG REPLICATION RATE #######
### Genomes Included ###
echo -ne "list of Genome included for SMEG reference database creation is listed in the Raw_data/SMEG/SMEG_Cluster_information.xlsx"

### Build Species ###
echo -ne "building smeg database from genomes"
smeg build_species -g ${in_data_dir_genomes} \
		   -o ${out_database} \
	           -a \
		   -p ${threads}

### growth estimation ###
echo -ne "estimating smeg replication rate from metagenomes"
smeg growth_est -o ${out_results} \
		-r ${in_data_dir_metagenomes} \
		-s ${out_database}/T.{X.X} \ # from build_species
		-p ${threads} \
		-x fastq.gz \
		-m 0 \
		-d 0.2 \
		-t 0.6 \
		-u 100 \
		-c 5 


###### BBMAP UNIQUE MAP ABUNDANCE #######
### Genomes Included ###
echo -ne "Reference database includes seven concatenated reference genomes"

### Mapped reads using BBMAP (Considers best top reads for all scaffold with 100% sequence similarity) ###
bbmap.sh in1=${Metagenome}_R1.fastq.gz \
	 in2=${Metagenome}_R2.fastq.gz \
	 ref={reference_genomes.fa} \
	 idfilter=1 \
	 perfectmode=t \
	 threads=${threads} \
	 ambiguous=all \
	 qtrim=lr \
	 minaveragequality=25 \
	 trimq=22 \
	 scafstats=${reference_scaf_stats.txt} \
	 out=${out.sam} 2> ${out.log}

### Finalize the results ### 
count=$( cat ${out.log} | grep "Reads Used:" | cut -f2 )
cat ${reference_scaf_stats.txt} | sed "s/$/\t$count/" | sed -n '2,8p' | sort -k1 | \
	sed '1i Genome\t%UniqueMapped_reads\tUniqueMapped_MB\t%MultiMapped_reads\tMultiMapped_MB\t#UniqueMapped_reads\t#MultiMapped_reads\t#Assigned_reads\tAssigned_bases\t#Total_reads' > ${stats_final.txt}
