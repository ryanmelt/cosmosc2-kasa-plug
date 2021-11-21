# encoding: ascii-8bit

# Create the overall gemspec
spec = Gem::Specification.new do |s|
  s.name = 'cosmosc2-kasa-plug'
  s.summary = 'COSMOS Plugin to Connect to Kasa Smart Plugs'
  s.description = <<-EOF
    This plugin an Interface and Target to Connect COSMOS to a Kasa Smart Plug
  EOF
  s.authors = ['Ryan Melton']
  s.homepage = 'https://github.com/ryanmelt/cosmosc2-kasa-plug'

  s.platform = Gem::Platform::RUBY

  if ENV['VERSION']
    s.version = ENV['VERSION'].dup
  else
    time = Time.now.strftime("%Y%m%d%H%M%S")
    s.version = '0.0.0' + ".#{time}"
  end
  s.license = 'MIT'

  s.files = Dir.glob("{targets,lib,procedures,tools,microservices}/**/*") + %w(Rakefile LICENSE.txt README.md plugin.txt)

  s.add_runtime_dependency 'cosmos'
end
