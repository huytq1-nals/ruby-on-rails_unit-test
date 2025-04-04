class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.integer :user_id
      t.integer :priority
      t.integer :amount
      t.integer :status
      t.string :order_type
      t.boolean :flag, default: false

      t.timestamps
    end
  end
end
