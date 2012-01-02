require 'phgx'

module Matador
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/matador"

  Matador.claim Matador.root.find, :rake, Rbbt.share.install.Matador.Rakefile.find(:lib)
end
