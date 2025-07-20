puts "Admin Users:"
AdminUser.all.each do |user|
  puts "#{user.email}"
end