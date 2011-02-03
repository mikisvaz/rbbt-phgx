# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rbbt-phgx}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Miguel Vazquez"]
  s.date = %q{2010-12-10}
  s.description = %q{Pharmaco-genomics related data sources}
  s.email = %q{miguel.vazquez@fdi.ucm.es}
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = [
    "LICENSE",
    "lib/phgx.rb",
    "lib/rbbt/sources/cancer.rb",
    "lib/rbbt/sources/kegg.rb",
    "lib/rbbt/sources/matador.rb",
    "lib/rbbt/sources/nci.rb",
    "lib/rbbt/sources/pharmagkb.rb",
    "lib/rbbt/sources/stitch.rb",
    "lib/rbbt/sources/string.rb",
    "share/install/KEGG/Rakefile",
    "share/install/Matador/Rakefile",
    "share/install/NCI/Rakefile",
    "share/install/PharmaGKB/Rakefile",
    "share/install/STITCH/Rakefile",
    "share/install/STRING/Rakefile",
    "share/install/lib/rake_helper.rb"
  ]
  s.homepage = %q{http://github.com/mikisvaz/rbbt-phgx}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Pharmaco-genomics for the Ruby Bioinformatics Toolkit (rbbt)}
  s.test_files = [
    "test/rbbt/sources/test_cancer.rb",
    "test/rbbt/sources/test_matador.rb",
    "test/rbbt/sources/test_pharmagkb.rb",
    "test/rbbt/sources/test_stitch.rb",
    "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
