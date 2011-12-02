require 'phgx'

module STRING
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/string"

  STRING.claim STRING.root.find, :rake, Rbbt.share.install.STRING.Rakefile.find(:lib)
end
