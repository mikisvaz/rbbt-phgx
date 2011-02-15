require 'rbbt/util/data_module'
require 'phgx'

module Reactome
  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then  Reactome.protein_pathway.produce end
