require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/fireDB'

class TestFireDB < Test::Unit::TestCase
  def test_true
    accession = "A6NFZ4"
    sequence = "MAKMFDLRTKIMIGIGSSLLVAAMVLLSVVFCLYFKVAKALKAAKDPDAVAVKNHNPDKVCWATNSQAKATTMESCPSLQCCEGCRMHASSDSLPPCCCDINEGL"
    mutation = "Y34D"

    puts FireDB.predict(accession, sequence, mutation)
  end
end

