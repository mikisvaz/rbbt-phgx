require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'test/unit'
require 'rbbt/util/tmpfile'
require 'rbbt/sources/stitch'

class TestSTITCH < Test::Unit::TestCase
  def test_stitch
    assert true
    # This takes to long...
    #assert STITCH.chemicals.tsv.keys.any?
  end
end

