require 'csv'

class OrderProcessingService
  def initialize(api_client)
    @api_client = api_client
  end

  def process_orders(user_id)
    orders = Order.where(user_id: user_id)
    return false if orders.blank?

    orders.each{ |order| process_order(order, user_id) }

    true
  rescue StandardError => e
    false
  end

  private

  def process_order(order, user_id)
    process_by_type(order, user_id)
    set_priority(order)
    save_order(order)
  end

  def process_by_type(order, user_id)
    case order.order_type
    when 'A' then process_type_a(order, user_id)
    when 'B' then process_type_b(order)
    when 'C' then process_type_c(order)
    else order.status = :unknown_type
    end
  end

  def set_priority(order)
    order.priority = order.amount > 200 ? :high : :low
  end

  def save_order(order)
    order.save!
  rescue DatabaseException
    order.update(status: :db_error)
  end

  def process_type_a(order, user_id)
    file_name = "orders_type_A_#{user_id}_#{Time.now.to_i}.csv"
    CSV.open(file_name, 'w') do |csv|
      csv << %w[ID Type Amount Flag Status Priority]
      csv << [order.id, order.order_type, order.amount, order.flag, order.status, order.priority]
      csv << ['', '', '', '', 'Note', 'High value order'] if order.amount > 150
    end
    order.status = :exported
  rescue StandardError
    order.status = :export_failed
  end

  def process_type_b(order)
    response = @api_client.call_api(order.id)
    if response.status == 'success'
      if response.data >= 50 && order.amount < 100
        order.status = :processed
      elsif response.data < 50 || order.flag
        order.status = :pending
      else
        order.status = :error
      end
    else
      order.status = :api_error
    end
  rescue ApiException
    order.status = :api_failure
  end

  def process_type_c(order)
    order.status = order.flag ? :completed : :in_progress
  end
end
