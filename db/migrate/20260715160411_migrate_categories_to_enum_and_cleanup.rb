class MigrateCategoriesToEnumAndCleanup < ActiveRecord::Migration[8.1]
  CATEGORY_MAP = {
    "Technology" => 1,
    "Lifestyle" => 20,
    "Travel" => 23,
    "Food" => 24,
    "Health" => 21,
    "Business" => 14
  }.freeze

  def up
    add_column :posts, :category, :integer, null: false, default: 0

    execute <<-SQL.squish
      UPDATE posts
      SET category = CASE
        #{CATEGORY_MAP.map { |name, val| "WHEN c.name = '#{name}' THEN #{val}" }.join("\n        ")}
        ELSE 0
      END
      FROM posts p
      INNER JOIN categories_posts cp ON cp.post_id = p.id
      INNER JOIN categories c ON c.id = cp.category_id
      WHERE posts.id = p.id
    SQL

    drop_table :categories_posts
    drop_table :categories
  end

  def down
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true

    create_table :categories_posts, id: false do |t|
      t.integer :category_id, null: false
      t.integer :post_id, null: false
    end
    add_index :categories_posts, [:category_id, :post_id]
    add_index :categories_posts, [:post_id, :category_id]

    CATEGORY_MAP.each do |name, val|
      cat = ActiveRecord::Base.connection.execute(
        "INSERT INTO categories (name, slug, created_at, updated_at) VALUES ('#{name}', '#{name.parameterize}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id"
      ).first
      cat_id = cat["id"]
      ActiveRecord::Base.connection.execute(
        "INSERT INTO categories_posts (category_id, post_id) SELECT #{cat_id}, id FROM posts WHERE category = #{val}"
      )
    end

    remove_column :posts, :category
  end
end
