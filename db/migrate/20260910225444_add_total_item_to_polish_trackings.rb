class AddTotalItemToPolishTrackings < ActiveRecord::Migration[8.1]
  def change
    add_column :polish_trackings, :total_item, :integer
  end
end
