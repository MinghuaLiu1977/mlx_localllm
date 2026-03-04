require 'xcodeproj'

project_path = '/Users/minghualiu/personal/EastlakeStudio/ofdviewer/flutter_app/macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# SPM Package Repository
package_url = 'https://github.com/ml-explore/mlx-swift-lm.git'
package_requirement = {
    'kind' => 'branch',
    'branch' => 'main'
}

# 1. Add the package reference to the project
package_ref = project.root_object.package_references.find { |p| p.repositoryURL == package_url }
if package_ref.nil?
  puts "Adding Swift Package: #{package_url}"
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = package_url
  package_ref.requirement = package_requirement
  project.root_object.package_references << package_ref
else
  puts "Swift Package already exists."
end

# 2. Add the product dependencies to the main target
target = project.targets.find { |t| t.name == 'Runner' }

['MLXLLM', 'MLXLMCommon', 'MLX', 'Tokenizers', 'Hub'].each do |product_name|
  dependency = target.package_product_dependencies.find { |d| d.product_name == product_name }
  if dependency.nil?
    puts "Adding Package Product Dependency: #{product_name}"
    dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dependency.package = package_ref
    dependency.product_name = product_name
    target.package_product_dependencies << dependency
  else
    puts "Package Product Dependency #{product_name} already exists."
  end
end

project.save
puts "Successfully added SPM dependencies to ofdviewer macOS app."
