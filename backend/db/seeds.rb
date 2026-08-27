EventType.find_or_create_by!(name: "Intro Call") do |et|
  et.description = "A quick 15-minute introductory call."
  et.duration_minutes = 15
end

EventType.find_or_create_by!(name: "Consultation") do |et|
  et.description = "A 30-minute consultation session."
  et.duration_minutes = 30
end

EventType.find_or_create_by!(name: "Deep Dive") do |et|
  et.description = "A 60-minute in-depth working session."
  et.duration_minutes = 60
end

puts "Seeded #{EventType.count} event types."
