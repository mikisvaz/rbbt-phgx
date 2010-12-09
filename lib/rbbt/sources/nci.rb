require 'phgx'
require 'rbbt/util/data_module'

module NCI
  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then NCI.all end
