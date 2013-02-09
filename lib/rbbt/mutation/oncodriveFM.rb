require 'rbbt-util'
require 'rbbt/util/open'
require 'rbbt/tsv'
require 'digest/md5'
require 'rbbt/sources/organism'

module OncodriveFM

  Rbbt.claim Rbbt.software.opt.OncodriveFM, :install, Rbbt.share.install.software.OncodriveFM.find


  def self.process_cohort(cohort, return_inputs = false)

    all_mutated_isoforms = cohort.metagenotype.mutated_isoforms.compact.flatten.uniq
    nonsense = all_mutated_isoforms.select{|mi| mi.consequence == "MISS-SENSE"}

    mutation_assessor = MutEval.job(:mutation_assessor, "OncodriveFM", :mutations => all_mutated_isoforms.subset(nonsense)).run
    sift              = MutEval.job(:sift, "OncodriveFM", :mutations => all_mutated_isoforms.subset(nonsense)).run
    #polyphen          = MutEval.job(:polyphen, "OncodriveFM", :mutations => all_mutated_isoforms.subset(nonsense)).run

    mutation_assessor_max = mutation_assessor.slice("Mutation Assessor Score").values.flatten.collect{|v| (v.nil? or v.empty?) ? nil : v.to_f}.compact.max
    sift_max              = sift.slice("SIFT Score").values.flatten.collect{|v| (v.nil? or v.empty?) ? nil : v.to_f}.compact.min

    mutation_assessor_mean = Misc.mean(mutation_assessor.slice("Mutation Assessor Score").values.flatten.collect{|v| (v.nil? or v.empty?) ? nil : v.to_f}.compact)
    sift_mean              = Misc.mean(sift.slice("SIFT Score").values.flatten.collect{|v| (v.nil? or v.empty?) ? nil : v.to_f}.compact)
    #polyphen_max          = polyphen.slice("Polyphen Score").values.flatten.collect{|v| (v.nil? or v.empty?) ? nil : v.to_f}.compact.max

    mutation_file = []
    cohort.each do |genotype|
      sample = genotype.jobname
      genotype.each do |mutation|
        genes = mutation.genes
        next if genes.empty?
        mut_mis = mutation.mutated_isoforms || []
        next if mut_mis.empty? and not mutation.in_exon_junction?
        genes.each do |gene|

          mis = mut_mis.select{|mi| mi.protein and mi.protein.gene == gene}

          mutation_assessor.values_at(*mis)
          ma_score       = mutation_assessor.values_at(*mis).compact.collect{|v| v["Mutation Assessor Score"]}.compact.collect{|v| v.to_f}.sort.last
          sift_score     = sift.values_at(*mis).compact.collect{|v| v["SIFT Score"]}.compact.collect{|v| v.to_f}.sort.first
          #polyphen_score = polyphen.values_at(*mis).compact.collect{|v| v["Polyphen Score"]}.compact.collect{|v| v.to_f}.sort.first

          ma_score       = mutation_assessor_max if mis.select{|mi| mi.truncated }.any? or mutation.in_exon_junction?
          sift_score     = sift_max            if mis.select{|mi| mi.truncated }.any? or mutation.in_exon_junction?

          ma_score       = mutation_assessor_mean if ma_score.nil? and mis.select{|mi| mi.consequence == "Indel" or mi.consequence == "Frameshift"}.any?
          sift_score     = sift_mean              if sift_score.nil? and mis.select{|mi| mi.consequence == "Indel" or mi.consequence == "Frameshift"}.any?

          #polyphen_score = polyphen_max    if mis.select{|mi| mi.truncated}.any?

          #mutation_file << [gene, sift_score || "NA", polyphen_score || "NA", ma_score || "NA", sample] * "\t"
          mutation_file << [gene, sift_score || "NA", ma_score || "NA", sample] * "\t"
        end
      end
    end

    TmpFile.with_file(mutation_file * "\n") do |fmuts|
      TmpFile.with_file do |outdir|
        FileUtils.mkdir_p outdir unless File.exists? outdir
        name = "Tumor"

        config_string = config(fmuts, outdir, "[TUMOR]" => name)
        TmpFile.with_file(config_string) do |fconf|
          CMD.cmd("cd #{Rbbt.software.opt.OncodriveFM.bin.find}; ./pipeline_launcher.pl '#{fconf}'").read
        end

        outfile = File.join(outdir, name + '.fimp')
        text = Open.read(outfile).gsub(/WARNING.*?\n/m,'').gsub(/\t-\t/,"\t\t").gsub(/\t-$/,"\t")
        tsv = TSV.open(StringIO.new(text), :type => :list)
        tsv.key_field = "Ensembl Gene ID"
        tsv.fields = ["Associated Gene Name", "Sample count", "p-value", "unknown"]

        return_inputs ? [tsv, mutation_file * "\n", config_string] : tsv
      end
    end

  end

  CONFIG_TEMPLATE=<<-EOF
###########################################################################################
# Input data specific for the tumor under analysis

#tumor: This name will be used as prefix to name all intermediate and final pipeline files
tumor='[TUMOR]'

#mutfile: File that contains the mutations data of the tumor you want to analyze. Each row corresponds to the mutation of one gene in one sample. Its format should be:
#
####Ensembl_Gene_ID MA_Zscore CHASM_Zscore  Sample_ID
mutfile='[MUTFILE]'

####numFIS: number of functional scores included in the mutations file and used to compute the functional impact bias
numFIS='[NUMFIS]'

###########################################################################################

###########################################################################################
# Common input data (change these only if you have downloaded different info files)

#genes2gos: File that contains the genes2gos mapping
genes2gos='[DATA_DIR]/common/slimgos_distrib/genes2gos'

#gosdistribs: Directory with the files that contain the distributions of SIFT, PPH2 and MA scores for each slimGOA obtained from 1000genomes.
gosdistribs='[DATA_DIR]/common/slimgos_distrib/'

#genes2symbols: File that contains the genes2symbols mapping obtained from BioMart. Its format should be:
#
####Ensembl_Gene_ID Gene_Symbol
genes2symbols='[DATA_DIR]/common/genes2symbols.txt'

extrec='NONE'

#genes2probes: File that contains the genes2probes mapping obtained from BioMart. Its format should be:
#
####Ensembl_Gene_ID Probe_ID
cp='[DATA_DIR]/common/cp.format'

#genesattr: File that contains genes' longest CDS' lengths obtained from BioMart and genes' basal nsSNVs rates computed from 1000genomes. This are used to assess the statistical significance of genes' mutations recurrence and genes' overmutation rates. Its format should be:
#
####Ensembl_Gene_ID Longest_CDS_length  Basal_nsSNVs_rate
genesattr='[DATA_DIR]/common/ensgenes_cds.recurrence'

#outdir: Directory to write output files
outdir='[OUTDIR]'

#tmpdir: Directory to write intermediate files
tmpdir='[TMPDIR]'

#internal: whether the null distribution will be taken from variants observed in the tumor
internal='[INTERNAL]'
###########################################################################################
  EOF

  def self.config(mutfile, outdir, options = {})
    options = Misc.add_defaults options, 
      "[TUMOR]" => "Tumor",
      "[MUTFILE]" => mutfile,
      #"[NUMFIS]" => 3,
      "[NUMFIS]" => 2,
      "[DATA_DIR]" => Rbbt.software.opt.OncodriveFM.data.find,
      "[OUTDIR]" => outdir,
      "[TMPDIR]" => Rbbt.tmp.OncodriveFM.find,
      "[INTERNAL]" => 1

    FileUtils.mkdir_p options["[TMPDIR]"] unless File.exists? options["[TMPDIR]"]

    txt = CONFIG_TEMPLATE.dup
    options.each do |key,value|
      txt.gsub!(key, value.to_s)
    end

    txt
  end

end
