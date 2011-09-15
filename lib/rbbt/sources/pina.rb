require 'phgx'

module Pina
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/pina"

  Pina.claim Pina.root.find, :rake, Rbbt.share.install.Pina.Rakefile.find(:lib)
end
