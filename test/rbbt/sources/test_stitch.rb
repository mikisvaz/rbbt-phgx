require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'test/unit'
require 'rbbt/util/tmpfile'
require 'rbbt/sources/stitch'

class TestSTITCH < Test::Unit::TestCase
  def test_stitch
    assert TSV.new(STITCH.chemicals).keys.any?
  end
end

