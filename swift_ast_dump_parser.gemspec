Gem::Specification.new do |s|
  s.name        = 'swift-ast-dump-parser'
  s.version     = '0.0.1'
  s.date        = '2017-11-12'
  s.summary     = 'Swift AST dump parser'
  s.description = <<-THEEND
  Tool that allows to build AST tree representation from the swift's AST dump
  swift-ast-dump-parser <ast-file>
THEEND
  s.authors     = ['Paul Taykalo']
  s.email       = 'tt.kilew@gmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    =
      'https://github.com/PaulTaykalo/swift-ast-dump-parser.git'
  s.license       = 'MIT'
  s.executables << 'swift-ast-dump-parser'
end