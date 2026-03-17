#!/usr/bin/env ruby

# Xcode 项目文件添加工具 - 适配 Xcode 15+ 文件系统同步
# 使用方法：ruby add_files_to_xcode.rb

require 'xcodeproj'

# 项目路径
project_path = 'ShapeMatch.xcodeproj'

# 打开项目
project = Xcodeproj::Project.open(project_path)

# 获取主 target
target = project.targets.first

# 要添加的文件
files_to_add = [
  'ShapeMatch/Services/ImageAlignment/ImageAlignmentProtocol.swift',
  'ShapeMatch/Services/ImageAlignment/VisionImageAlignment.swift',
  'ShapeMatch/Services/ImageAlignment/ImageAlignmentService.swift'
]

puts "正在添加文件到 Xcode 项目..."
puts ""

# 由于 Xcode 15+ 使用文件系统同步，我们直接添加文件引用到主组
main_group = project.main_group

# 尝试找到 ShapeMatch 组
shape_match_group = main_group.children.find do |child|
  child.is_a?(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup) ||
  (child.is_a?(Xcodeproj::Project::Object::PBXGroup) && (child.name == 'ShapeMatch' || child.path == 'ShapeMatch'))
end

if shape_match_group.nil?
  puts "⚠️  未找到 ShapeMatch 组，将添加到主组"
  ref_group = main_group
else
  puts "✅ 找到 ShapeMatch 组"
  ref_group = shape_match_group
end

# 添加文件
files_to_add.each do |file_path|
  # 检查文件是否真实存在
  unless File.exist?(file_path)
    puts "⚠️  文件不存在，跳过: #{file_path}"
    next
  end

  # 创建文件引用
  file_ref = ref_group.new_file(file_path)

  # 添加到编译阶段
  target.add_file_references([file_ref])

  puts "✅ 已添加: #{file_path}"
end

# 保存项目
project.save

puts ""
puts "✨ 文件添加完成！"
puts ""
puts "提示：如果 Xcode 没有自动识别文件，请："
puts "  1. 在 Xcode 中关闭项目"
puts "  2. 重新打开 ShapeMatch.xcodeproj"
puts "  3. 如果文件显示为红色，右键选择 'Locate File'"
