require 'phgx'
require 'rbbt/util/data_module'

module Cancer
  PhGx.claim :anais_annotations, nil, 'Cancer'
  PhGx.claim :anais_interactions, nil, 'Cancer'

  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then Cancer.anais_annotations.produce end
