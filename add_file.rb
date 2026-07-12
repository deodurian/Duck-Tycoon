require 'xcodeproj'
project_path = 'jeu tycoon.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('jeu tycoon', 'Sources', 'Models'), true)
file_ref = group.new_reference('BigNumber.swift')

target.add_file_references([file_ref])
project.save
