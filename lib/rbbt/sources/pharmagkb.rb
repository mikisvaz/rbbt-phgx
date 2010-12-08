require 'phgx'
require 'rbbt/util/data_module'

module PharmaGKB
  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then PharmaGKB.all end
