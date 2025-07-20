AdminUser.create!(
  email: 'admin@youtube-trends.com',
  password: 'password123',
  password_confirmation: 'password123'
)

puts "Admin user created successfully!"
puts "Email: admin@youtube-trends.com"
puts "Password: password123"