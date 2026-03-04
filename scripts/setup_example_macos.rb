require 'xcodeproj'

project_path = 'example/macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# SPM Package Repository
package_url = 'https://github.com/ml-explore/mlx-swift-lm.git'
package_requirement = {
  'kind' => 'upToNextMajorVersion',
  'minimumVersion' => '2.30.6'
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

# 3. Add Plugin Swift files to the Runner target
# This ensures they have access to SPM dependencies during compilation
plugin_macos_dir = File.expand_path('../../macos/Classes', __FILE__)
files_to_add = [
  'MlxLocalllmPlugin.swift',
  'NativeMLXService.swift',
  'HubApi+Compatible.swift'
]

# Find or create a group for the plugin
group_name = 'mlx_localllm'
group = project.main_group.find_subpath(group_name, true)

files_to_add.each do |file_name|
  file_path = File.join(plugin_macos_dir, file_name)
  
  # Check if file is already in the project
  file_ref = group.find_file_by_path(file_path)
  if file_ref.nil?
    puts "Adding Plugin Source: #{file_name}"
    file_ref = group.new_file(file_path)
    target.add_resources([file_ref]) if file_name.end_with?('.png') # Just in case
    target.add_file_references([file_ref])
  else
    puts "Plugin Source #{file_name} already exists in project."
  end
end

project.save
puts "Successfully added SPM dependencies and Plugin sources to macOS Example app."
