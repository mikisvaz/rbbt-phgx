require 'phgx'
require 'rbbt/util/data_module'

module STRING
  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then STRING.all end