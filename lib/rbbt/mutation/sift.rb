require 'rbbt/util/open'
require 'nokogiri'
module SIFT
  URL_AMINOACID="http://sift.jcvi.org/sift-bin/SIFT_pid_subst_all_submit.pl"
  URL_GENOMIC="http://sift.jcvi.org/sift-bin/SIFT_feed_to_chr_coords.pl"

  def self.predict_aminoacid_mutation(accession, mutations)
    doc = Nokogiri::HTML(Open.read(URL_AMINOACID, :wget_options => {"--post-data" => "'GI=#{[accession, mutations].flatten * ","}&sequences_to_select=BEST&seq_identity_filter=90'"}, :nocache => false))

    rows = []
    doc.css('tr').each do |row|
      rows << row.css('td').collect{|cell| cell.content}
    end

    rows.shift

    if Array === mutations
      rows
    else
      rows.first
    end
  end

  def self.parse_genomic_mutation(mutation)
    mutation.match(/(\d+):(\d+):(1|-1):([A-Z])\/([A-Z])/).values_at 1,2,3,4,5
  end

  def self.predict_genomic_mutation(mutations)
    mutations = [mutations] unless Array === mutations
    codes = mutations.collect{|mutation|
      parts = parse_genomic_mutation(mutation)
      parts[0..2] * ',' + ",#{parts[3]}/#{parts[4]}"
    }

    return Open.read(URL_GENOMIC, :wget_options => {"--post-data" => "'CHR=#{codes * "\n"}'", :nocache => false})

#    doc = Nokogiri::HTML(Open.read(URL_GENOMIC, :wget_options => {"--post-data" => "'CHR=#{codes * "\n"}"))
#
#
#    rows = []
#    doc.css('tr').each do |row|
#      rows << row.css('td').collect{|cell| cell.content}
#    end
#
#    rows.shift
#
#    if Array === mutations
#      rows
#    else
#      rows.first
#    end
  end

end
