desc 'Aliasing rails routes to rake routes for annotate gem'
task routes: :environment do
  puts `bin/rails routes`
end
