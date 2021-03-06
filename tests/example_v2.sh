echo "
This is an example script demonstrating the software used in the manuscript:
'Combining HIV-1 Viral Genetics and Statistical Modeling to Improve Very Recent Time-of-infection Estimation Towards Enhanced Vaccine Efficacy Assessment'.

This script will:
1) Call identify_founders.pl repeatedly to compute metrics based on input alignment files.
2) Collate all these metrics into a single file.
3) Call estimateInfectionTime.R to use the calibrated models to produce/refine the metrics produced by identify_founders.pl.
"

mkdir -p /tmp/hf_example_v2

cd /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id

perl /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/identify_founders.pl -PRT -o /tmp/hf_example_v2/example_1 /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v2/example_1.fasta
perl /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/identify_founders.pl -PRT -o /tmp/hf_example_v2/example_2 /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v2/example_2.fasta
perl /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/identify_founders.pl -PRT -o /tmp/hf_example_v2/example_3 /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v2/example_3.fasta
perl /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/identify_founders.pl -PRT -o /tmp/hf_example_v2/example_4 /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v2/example_4.fasta
perl /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/identify_founders.pl -PRT -o /tmp/hf_example_v2/example_5 /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v2/example_5.fasta
perl /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/identify_founders.pl -PRT -o /tmp/hf_example_v2/example_6 /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v2/example_6.fasta
perl /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/identify_founders.pl -PRT -o /tmp/hf_example_v2/example_7 /home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v2/example_7.fasta

# collate identify_founders.tab files
cp /tmp/hf_example_v2/example_1/identify_founders.tab /tmp/hf_example_v2/identify_founders.tab
tail -n 1 /tmp/hf_example_v2/example_2/identify_founders.tab >> /tmp/hf_example_v2/identify_founders.tab
tail -n 1 /tmp/hf_example_v2/example_3/identify_founders.tab >> /tmp/hf_example_v2/identify_founders.tab
tail -n 1 /tmp/hf_example_v2/example_4/identify_founders.tab >> /tmp/hf_example_v2/identify_founders.tab
tail -n 1 /tmp/hf_example_v2/example_5/identify_founders.tab >> /tmp/hf_example_v2/identify_founders.tab
tail -n 1 /tmp/hf_example_v2/example_6/identify_founders.tab >> /tmp/hf_example_v2/identify_founders.tab
tail -n 1 /tmp/hf_example_v2/example_7/identify_founders.tab >> /tmp/hf_example_v2/identify_founders.tab

# run estimateInfectionTime.R

/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/estimateInfectionTime.R --model_structure=slope --identify_founders.tab=/tmp/hf_example_v2/identify_founders.tab --estimator=pfitter

/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/estimateInfectionTime.R --model_structure=slope --identify_founders.tab=/tmp/hf_example_v2/identify_founders.tab --bounds_file=tests/example_data_v2/bounds_diff.csv --estimator=pfitter

/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/estimateInfectionTime.R --model_structure=full --identify_founders.tab=/tmp/hf_example_v2/identify_founders.tab --vl_file=tests/example_data_v2/vl_diff.csv --bounds_file=tests/example_data_v2/bounds_diff.csv --estimator=pfitter
