require 'phgx'
require 'rbbt/util/data_module'

module Cancer
  PhGx.claim :anais_annotations, 'Cancer/anais-annotations.txt', 'Cancer'
  PhGx.claim :anais_interactions, 'Cancer/anais-interactions.txt', 'Cancer'

  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then NCI.all end
