class CreatePolishTrackings < ActiveRecord::Migration[8.1]
  def change
    create_table :polish_trackings do |t|
      t.integer :order_id
      t.string :customer
      t.string :product
      t.integer :tracking_id
      t.integer :width
      t.integer :height
      t.string :polish_type
      t.integer :available
      t.integer :completed

      t.timestamps
    end
  end
end
