require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/mutation_assessor'

class TestMutationAssessor < Test::Unit::TestCase

  def _test_predict_aminoacid_mutation
    mutations = {
      "EGFR_HUMAN" => %w(R521K)
    }

    puts MutationAssessor.predict(mutations)
    assert_equal 1, MutationAssessor.predict(mutations).length
  end

  def _test_predict_aminoacid_mutation_tsv
    tsv = TSV.setup({"EGFR_HUMAN" => [%w(R521K)]}, :key_field => "UniProt/SwissProt ID", :fields => ["Protein Mutation"], :type => :double)

    assert_equal "neutral", MutationAssessor.add_predictions(tsv).slice("MutationAssessor:Prediction").values.first.flatten.first
    assert_equal 1, MutationAssessor.add_predictions(tsv).slice(["MutationAssessor:Prediction", "Protein Mutation"]).length
  end


  def test_predict_chunked
    mutations = {
      "EGFR_HUMAN" => %w(R521K),
      "P53_HUMAN" => %w(R21K),
    }

    puts MutationAssessor.chunked_predict(mutations)
  end




end

