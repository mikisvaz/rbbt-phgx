require 'phgx'
require 'rbbt/util/data_module'

module STITCH
  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then STITCH.all end
