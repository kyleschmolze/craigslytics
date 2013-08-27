require 'resque/tasks'

task "resque:setup" => :environment do
	ENV['QUEUE'] = '*'
  Resque.after_fork = Proc.new { ActiveRecord::Base.establish_connection }
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"

task "import" => :environment do
  # If today is sunday, run the importers
  if Date.today.wday == 0
    ListingImporter.find_each do |importer|
      ListingImporter.enqueue importer.id
    end

    User.find_each(:admin => false) do |user|
      Listing.enqueue user.id
    end
  
    #Resque.enqueue ZillowImporter, 1
    #Resque.enqueue CraigslistImporter
  end
end
