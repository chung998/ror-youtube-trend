User.all.each do  < /dev/null | u|
  puts "ID: #{u.id}, Email: #{u.email}, Admin: #{u.admin? ? 'YES' : 'NO'}, Created: #{u.created_at.strftime('%Y-%m-%d %H:%M')}"
end

puts "\n총 #{User.count}명의 사용자가 등록되어 있습니다."
puts "관리자는 #{User.where(admin: true).count}명입니다."
