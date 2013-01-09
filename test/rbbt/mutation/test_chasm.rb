require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/chasm'

class TestCHASM < Test::Unit::TestCase

  def test_predict_aminoacid_mutation
    sample_mutations = {
      "Sample_1" => ["ENST00000531739:R641W"]

    }
    ddd CHASM.predict(sample_mutations, :cancertype => "Breast")
  end
end

