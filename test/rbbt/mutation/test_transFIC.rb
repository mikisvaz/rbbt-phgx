require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/transFIC'

class TestTransFIC < Test::Unit::TestCase

  def test_predict_aminoacid_mutation
    mutations = [
      "ENSP00000275493:R521K"
    ]
    puts TransFIC.predict(mutations)
  end

end

