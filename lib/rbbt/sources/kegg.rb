require 'rbbt/util/data_module'
require 'phgx'

module KEGG
  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then  KEGG.all end
