class AddUserIdToPosts < ActiveRecord::Migration[8.1]
  def up
    default_user = User.find_or_create_by!(email: "admin@blog.local") do |u|
      u.name = "Blog Admin"
      u.password = SecureRandom.hex(16)
    end

    add_reference :posts, :user, null: true, foreign_key: true

    Post.where(user_id: nil).update_all(user_id: default_user.id)

    change_column_null :posts, :user_id, false
  end

  def down
    remove_reference :posts, :user, foreign_key: true
  end
end
