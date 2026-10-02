# Prints the team owning a fork org as JSON: {"team","leads","reviewer","fallback_reviewer"}.
# "team" is null when the org isn't registered. Usage: ruby team-of.rb <teams.yml> <org>
require "yaml"
require "json"

file, org = ARGV
cfg = YAML.safe_load(File.read(file)) || {}
teams = cfg["teams"] || {}
name, team = teams.find { |_, t| Array(t["orgs"]).any? { |o| o.to_s.casecmp?(org.to_s) } }

puts JSON.generate(
  "team" => name,
  "leads" => team ? Array(team["leads"]).map(&:to_s) : [],
  "reviewer" => team && team["reviewer"] ? team["reviewer"].to_s : nil,
  "fallback_reviewer" => cfg["fallback_reviewer"] ? cfg["fallback_reviewer"].to_s : nil
)
