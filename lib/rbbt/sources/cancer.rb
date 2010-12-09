require 'phgx'
require 'rbbt/util/data_module'

module Cancer
  PhGx.add_datafiles :anais_annotations => ['Cancer', 'Cancer/anais-annotations.txt'],
    :anais_interactions => ['Cancer', 'Cancer/anais-interactions.txt']

  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then NCI.all end
