class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.timestamps
    end
    add_index :comments, [:post_id, :created_at]
    add_column :posts, :comments_count, :integer, default: 0, null: false
  end
end
