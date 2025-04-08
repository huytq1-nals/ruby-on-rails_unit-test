FactoryBot.define do
  factory :order do
    order_type { 'A' }
    amount { 100 }
    flag { false }
    status { 'new_status' }
    priority { 'low' }
  end
end
