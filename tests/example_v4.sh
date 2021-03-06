# Start of configuration section

# TODO: List input files
declare -a input_files=(
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p01_mu_3_50k_gen_8.fasta"
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p02_mu_4_50k_gen_8.fasta"
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p03_mu_3_50k_gen_10.fasta"
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p04_mu_4_50k_gen_10.fasta"
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p05_mu_3_50k_gen_12.fasta"
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p06_mu_4_50k_gen_12.fasta"
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p07_mu_3_50k_gen_8_hyper.fasta"
"/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/p08_mu_4_50k_gen_12_hyper.fasta"
)

# TODO: Specify output folder
output_folder="/tmp/example_v4"

# TODO: Specify path to the pipeline folder
pipeline_folder="/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id"

# TODO: Optional: Specify viral loads file
vl_file="/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/vl_diff.csv"

# TODO: Optional: Specify bounds file
bounds_file="/home/phillipl/projects/hiv-founder-id/code/hiv-founder-id/tests/example_data_v4/bounds_diff.csv"

# End of configuration section.

echo "
This is an example script demonstrating the software used in the manuscript:
'Combining HIV-1 Viral Genetics and Statistical Modeling to Improve Very Recent Time-of-infection Estimation Towards Enhanced Vaccine Efficacy Assessment.'

This script will:
STEP 1: Call identify_founders.pl repeatedly to compute metrics based on input alignment files.
STEP 2: Call estimateInfectionTime.R to use the calibrated models to produce/refine the metrics produced by identify_founders.pl.
"

echo "
====================================
STEP 1: Calling idenfity_founders.pl
====================================
"

output_folder="${output_folder%/}"
pipeline_folder="${pipeline_folder%/}"

in_len=${#input_files[@]}

# For reasons I don't understand, identify_founders.pl sometimes breaks if not run from within the pipeline folder
cd $pipeline_folder

mkdir -p $output_folder

for ((i = 0; i<$in_len; i++)); do
  c_out_folder="$(basename -- ${input_files[$i]})"
  c_out_folder="${c_out_folder%.*}"
  printf "\n\nNow running identify_founders.pl on file number $i.\nFile name: ${input_files[$i]}.\nOutput will be generated in $output_folder/$c_out_folder.\nDetailed output from identify_founders.pl:\n-------------------------------\n"
  perl identify_founders.pl -PRTC -o $output_folder/$c_out_folder ${input_files[$i]}
  if [ $i -eq 0 ]
  then
    rm $output_folder/identify_founders.tab
    cp $output_folder/$c_out_folder/identify_founders.tab $output_folder/identify_founders.tab
  else
    tail -n +2 $output_folder/$c_out_folder/identify_founders.tab >> $output_folder/identify_founders.tab
  fi
done

echo "

=======================================
STEP 2: Calling estimateInfectionTime.R
=======================================
"

$pipeline_folder/estimateInfectionTime.R --model_structure=slope --identify_founders.tab=$output_folder/identify_founders.tab --estimator=pfitter --debug
#
# Example of using estimateInfectionTime.R with a bounds file
#$pipeline_folder/estimateInfectionTime.R --model_structure=slope --identify_founders.tab=$output_folder/identify_founders.tab --bounds_file=tests/example_data_v2/bounds_diff.csv --estimator=pfitter
#
# Example of using estimateInfectionTime.R with the (overfitted) full model
#$pipeline_folder/estimateInfectionTime.R --model_structure=full --identify_founders.tab=$output_folder/identify_founders.tab --vl_file=$vl_file --bounds_file=$bounds_file --estimator=pfitter --debug

echo "
Estimation complete. 
To explore other calibrated models, either look at the output of '$pipeline_folder/estimateInfectionTime.R -h'.
"

