
Gem::Specification.new do |spec|
  spec.name          = "embulk-output-zendesk_users"
  spec.version       = "0.0.3"
  spec.authors       = ["Toru Takahashi"]
  spec.summary       = "Zendesk Users output plugin for Embulk"
  spec.description   = "Update Zendesk User's segments"
  spec.email         = ["torutakahashi.ayashi@gmail.com"]
  spec.licenses      = ["MIT"]
  spec.homepage      = "https://github.com/toru-takahashi/embulk-output-zendesk_users"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'embulk', ['>= 0.8.30']
  spec.add_development_dependency 'bundler', ['>= 1.10.6']
  spec.add_development_dependency 'rake', ['>= 10.0']
  spec.add_dependency 'zendesk_api', ['>=1.16.0']
end
