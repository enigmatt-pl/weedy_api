# db/seeds_dev.rb

puts "Cleaning up database..."
Dispensary.destroy_all
# Safely clear ActiveStorage records even if original models are missing
ActiveStorage::Attachment.delete_all
ActiveStorage::Blob.delete_all
ActiveStorage::VariantRecord.delete_all

sample_images = [
  "/Users/user/.gemini/antigravity/brain/472d47bc-1eeb-4696-a845-e77dc390f0c8/sample_dispensary_1_1776874643998.png",
  "/Users/user/.gemini/antigravity/brain/472d47bc-1eeb-4696-a845-e77dc390f0c8/sample_dispensary_2_1776874663432.png"
]

cities = [
  { name: "Warszawa", lat: 52.2297, lng: 21.0122 },
  { name: "Kraków", lat: 50.0647, lng: 19.9450 },
  { name: "Wrocław", lat: 51.1079, lng: 17.0385 },
  { name: "Gdańsk", lat: 54.3520, lng: 18.6466 },
  { name: "Poznań", lat: 52.4064, lng: 16.9252 },
  { name: "Katowice", lat: 50.2649, lng: 19.0238 },
  { name: "Łódź", lat: 51.7592, lng: 19.4560 },
  { name: "Szczecin", lat: 53.4285, lng: 14.5528 },
  { name: "Lublin", lat: 51.2465, lng: 22.5684 },
  { name: "Bydgoszcz", lat: 53.1235, lng: 18.0084 }
]

names = [
  "Green Life", "Wellness Leaf", "Bio Hemp Boutique", "Canna Paradise", 
  "The Healing Herb", "Nature's Pharmacy", "Eco Weed Shop", "Golden Bud", 
  "Pure Green Katowice", "Medical Flower"
]

categories_pool = ["cbd", "hemp", "medical", "accessories"]

user = User.first || User.create!(email: "admin@weedy.pl", password: "password", first_name: "Admin", last_name: "Weedy", role: :super_admin, approved: true, legal_version: "v1-beta", accepted_terms_at: Time.current, accepted_privacy_at: Time.current)

puts "Creating 10 sample dispensaries..."

10.times do |i|
  city = cities[i]
  name = names[i]
  
  dispensary = Dispensary.create!(
    user: user,
    title: "#{name} #{city[:name]}",
    description: "Profesjonalny punkt #{name} zaprasza wszystkich pacjentów i klientów poszukujących najwyższej jakości produktów konopnych. Oferujemy szeroki wybór asortymentu w samym sercu miasta #{city[:name]}.",
    city: city[:name],
    query_data: "ul. Główna #{rand(1..100)}, #{city[:name]}",
    latitude: city[:lat] + (rand - 0.5) * 0.05,
    longitude: city[:lng] + (rand - 0.5) * 0.05,
    categories: categories_pool.sample(rand(1..3)),
    phone: "+48 #{rand(100..999)} #{rand(100..999)} #{rand(100..999)}",
    email: "kontakt@#{name.parameterize}.pl",
    website: "https://#{name.parameterize}.pl",
    hours: "Pon-Pt: 10:00 - 20:00, Sob: 11:00 - 18:00",
    rating: rand(4.0..5.0).round(2),
    status: :published
  )
  
  # Attach random image from samples
  image_path = sample_images.sample
  if File.exist?(image_path)
    dispensary.images.attach(
      io: File.open(image_path),
      filename: File.basename(image_path)
    )
  end
  
  print "."
end

puts "\nDone! Created 10 dispensaries."
