require 'rbbt/util/data_module'
require 'phgx'

module Matador
  PKG = PhGx
  extend DataModule
end

if __FILE__ == $0 then  Matador.all end
