# Blog Posts — Plan de Extensión de Funcionalidad

> Documento de planificación para las 5 fases de desarrollo del proyecto Blog Posts (Rails 8.1.3 + SQLite + Tailwind CSS).

---

## Estado Actual del Proyecto

| Aspecto | Detalle |
|---------|---------|
| Framework | Ruby on Rails 8.1.3 |
| Base de datos | SQLite3 |
| Auth | Ninguno |
| Frontend | Tailwind CSS 4.6 + Hotwire (Turbo + Stimulus) |
| Asset pipeline | Propshaft |
| JS | Importmap (sin npm) |
| Uploads | Active Storage (`has_one_attached :image`) |
| Test framework | Minitest (sin tests escritos) |
| Deploy | Kamal + Thruster |

### Archivos Existentes

```
app/
  models/
    post.rb              # has_one_attached :image, validations
  controllers/
    posts_controller.rb  # Full CRUD
  views/
    layouts/application.html.erb
    posts/index.html.erb
    posts/show.html.erb
    posts/new.html.erb
    posts/edit.html.erb
    posts/_form.html.erb
config/
  routes.rb              # resources :posts, root "posts#index"
db/
  schema.rb              # posts table
  migrate/               # create_posts + active_storage_tables
test/
  models/post_test.rb    # Vacío
  fixtures/posts.yml     # Fixtures básicos
```

### Tablas Actuales

- `posts` (id, title, body, published, created_at, updated_at)
- `active_storage_blobs`, `active_storage_attachments`, `active_storage_variant_records`
- `schema_migrations`, `ar_internal_metadata`

---

## Fase 1 — Autenticación de Usuarios

### Objetivo
Crear sistema de registro, login y logout para que solo usuarios autenticados puedan crear/editar/borrar posts.

### Gem Requerida

```ruby
# Descomentar en Gemfile
gem "bcrypt", "~> 3.1.7"
```

### Generador

```bash
bin/rails generate authentication
```

Esto genera automáticamente:
- `app/models/current.rb` (Current.user via ActiveSupport::CurrentAttributes)
- `app/models/user.rb` (has_secure_password)
- `app/controllers/sessions_controller.rb` (create, destroy)
- `app/controllers/concerns/authentication.rb` (before_action, login/logout helpers)
- Migración `create_users`

### Cambios Manuales Necesarios

#### 1. Modelo `User` (generado, verificar)

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, if: :password_required?

  has_many :posts, dependent: :destroy

  private

  def password_required?
    new_record? || password.present?
  end
end
```

#### 2. Schema de Users (migración generada)

```ruby
# db/migrate/xxxxxx_create_users.rb
create_table :users do |t|
  t.string :email,           null: false
  t.string :name,            null: false
  t.string :password_digest, null: false
  t.timestamps
end
add_index :users, :email, unique: true
```

#### 3. Migration para agregar `user_id` a posts

```ruby
# db/migrate/xxxxxx_add_user_id_to_posts.rb
class AddUserIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :user, null: false, foreign_key: true
  end
end
```

> **NOTA:** Ejecutar esta migración DESPUÉS de tener la tabla users.
> Para posts existentes sin usuario, crear un usuario "default" y hacer backfill.

#### 4. Rutas

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Auth
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :posts
  root "posts#index"
end
```

> **Decisión:** Usar controllers manuales (`RegistrationsController`, `SessionsController`) en lugar del generador para tener control total. NO usar Devise en este proyecto — es overkill para auth básica.

#### 5. Controller de Registro

```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Account created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :password, :password_confirmation)
  end
end
```

#### 6. Application Controller

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
  stale_when_importmap_changes
end
```

#### 7. Proteger PostsController

```ruby
# Agregar before_action
before_action :require_login, only: [:new, :create, :edit, :update, :destroy]

# En private
def require_login
  unless Current.user
    redirect_to sign_in_path, alert: "You must be signed in."
  end
end

# En create, asociar usuario
def create
  @post = Current.user.posts.build(post_params)
  # ...
end
```

#### 8. Vistas de Auth

Crear:
- `app/views/registrations/new.html.erb` — Formulario de registro
- `app/views/sessions/new.html.erb` — Formulario de login

Crear partial:
- `app/views/shared/_auth_form.html.erb` — Formulario reutilizable

#### 9. Navbar Actualizada

```erb
<!-- En application.html.erb, agregar a la derecha del nav -->
<% if Current.user %>
  <span class="text-sm text-gray-600">Hi, <%= Current.user.name %></span>
  <%= button_to "Logout", logout_path, method: :delete, class: "..." %>
<% else %>
  <%= link_to "Sign In", sign_in_path, class: "..." %>
  <%= link_to "Sign Up", sign_up_path, class: "..." %>
<% end %>
```

### Archivos a Crear/Modificar

| Archivo | Acción |
|---------|--------|
| `Gemfile` | Descomentar `gem "bcrypt"` |
| `app/models/user.rb` | Crear |
| `app/models/current.rb` | Crear (si no lo genera el generador) |
| `app/controllers/registrations_controller.rb` | Crear |
| `app/controllers/sessions_controller.rb` | Crear |
| `app/controllers/application_controller.rb` | Modificar (include Authentication) |
| `app/controllers/posts_controller.rb` | Modificar (require_login, asociar user) |
| `app/views/registrations/new.html.erb` | Crear |
| `app/views/sessions/new.html.erb` | Crear |
| `app/views/layouts/application.html.erb` | Modificar (navbar auth) |
| `config/routes.rb` | Modificar |
| `db/migrate/xxx_create_users.rb` | Generar + modificar |
| `db/migrate/xxx_add_user_id_to_posts.rb` | Crear |

### Pruebas

```ruby
# test/models/user_test.rb
class UserTest < ActiveSupport::TestCase
  test "valid user with all attributes" do
    user = User.new(email: "test@example.com", name: "Test", password: "password123")
    assert user.valid?
  end

  test "requires email" do
    user = User.new(name: "Test", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    User.create!(email: "taken@example.com", name: "Test", password: "password123")
    duplicate = User.new(email: "taken@example.com", name: "Test2", password: "password123")
    assert_not duplicate.valid?
  end

  test "requires valid email format" do
    user = User.new(email: "not-an-email", name: "Test", password: "password123")
    assert_not user.valid?
  end

  test "requires password minimum 6 characters" do
    user = User.new(email: "test@example.com", name: "Test", password: "12345")
    assert_not user.valid?
  end

  test "has many posts" do
    user = User.create!(email: "test@example.com", name: "Test", password: "password123")
    assert_respond_to user, :posts
  end
end

# test/controllers/sessions_controller_test.rb
class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get sign in page" do
    get sign_in_path
    assert_response :success
  end

  test "should sign in with valid credentials" do
    user = User.create!(email: "test@example.com", name: "Test", password: "password123")
    post sign_in_path, params: { email: "test@example.com", password: "password123" }
    assert_redirected_to root_path
  end

  test "should not sign in with invalid credentials" do
    post sign_in_path, params: { email: "wrong@example.com", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "should logout" do
    user = User.create!(email: "test@example.com", name: "Test", password: "password123")
    post sign_in_path, params: { email: "test@example.com", password: "password123" }
    delete logout_path
    assert_redirected_to root_path
  end
end

# test/controllers/registrations_controller_test.rb
class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get sign up page" do
    get sign_up_path
    assert_response :success
  end

  test "should register with valid data" do
    assert_difference("User.count", 1) do
      post sign_up_path, params: {
        user: { email: "new@example.com", name: "New", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_redirected_to root_path
  end

  test "should not register with invalid data" do
    assert_no_difference("User.count") do
      post sign_up_path, params: {
        user: { email: "", name: "", password: "123" }
      }
    end
    assert_response :unprocessable_entity
  end
end
```

---

## Fase 2 — Autoría de Posts

### Objetivo
Cada post pertenece a un usuario. Solo el autor puede editar/borrar su post.

### Cambios Necesarios

#### 1. Modelo Post (modificar)

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  validates :title, presence: true, length: { minimum: 3 }
  validates :body, presence: true
  validate :acceptable_image

  # ... (validaciones de imagen existentes)
end
```

#### 2. Modelo User (ya modificado en Fase 1)

```ruby
has_many :posts, dependent: :destroy
```

#### 3. PostsController (modificar)

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy]
  before_action :authorize_post, only: [:edit, :update, :destroy]

  def create
    @post = Current.user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: "Post was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post was deleted."
  end

  private

  def authorize_post
    unless @post.user == Current.user
      redirect_to posts_path, alert: "You are not authorized to perform this action."
    end
  end
end
```

#### 4. Vista show — Mostrar autor

```erb
<!-- En show.html.erb, debajo del título -->
<div class="flex items-center gap-3 mb-4">
  <h1 class="text-3xl font-bold text-gray-900"><%= @post.title %></h1>
  <!-- badges existentes -->
</div>
<p class="text-sm text-gray-500 mb-4">
  By <span class="font-medium text-gray-700"><%= @post.user.name %></span>
  · <%= time_ago_in_words(@post.created_at) %> ago
</p>
```

#### 5. Vista index — Mostrar autor en cards

```erb
<!-- En cada card, antes del título -->
<p class="text-xs text-gray-500 mb-1">By <%= post.user.name %></p>
```

#### 6. Botones de Edit/Delete — Solo para el autor

```erb
<% if Current.user == post.user %>
  <div class="flex items-center gap-3">
    <%= link_to "Edit", edit_post_path(post), class: "..." %>
    <%= button_to "Delete", post, method: :delete, data: { confirm: "..." }, class: "..." %>
  </div>
<% end %>
```

#### 7. Backfill de posts existentes

Crear usuario "default" antes de la migración:

```ruby
# db/migrate/xxxxxx_add_user_id_to_posts.rb
class AddUserIdToPosts < ActiveRecord::Migration[8.1]
  def up
    default_user = User.find_or_create_by!(email: "default@blog.local") do |u|
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
```

### Archivos a Modificar

| Archivo | Acción |
|---------|--------|
| `app/models/post.rb` | Agregar `belongs_to :user` |
| `app/controllers/posts_controller.rb` | Agregar authorize_post, crear con Current.user |
| `app/views/posts/show.html.erb` | Mostrar autor |
| `app/views/posts/index.html.erb` | Mostrar autor + condicionar botones |
| `db/migrate/xxx_add_user_id_to_posts.rb` | Crear |

### Pruebas

```ruby
# test/models/post_test.rb
class PostTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "author@example.com", name: "Author", password: "password123")
  end

  test "post belongs to user" do
    post = @user.posts.create!(title: "Test", body: "Content")
    assert_equal @user, post.user
  end

  test "post requires user" do
    post = Post.new(title: "Test", body: "Content")
    assert_not post.valid?
    assert_includes post.errors[:user], "must exist"
  end

  test "destroying user destroys posts" do
    @user.posts.create!(title: "Test", body: "Content")
    assert_difference("Post.count", -1) { @user.destroy }
  end
end

# test/controllers/posts_controller_test.rb
class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com", name: "Test", password: "password123")
    @post = @user.posts.create!(title: "Test Post", body: "Content", published: true)
  end

  test "unauthenticated user cannot create post" do
    assert_no_difference("Post.count") do
      post posts_path, params: { post: { title: "New", body: "Body" } }
    end
    assert_redirected_to sign_in_path
  end

  test "user cannot edit another user's post" do
    other_user = User.create!(email: "other@example.com", name: "Other", password: "password123")
    post sign_in_path, params: { email: "other@example.com", password: "password123" }

    patch post_path(@post), params: { post: { title: "Hacked" } }
    assert_redirected_to posts_path
    @post.reload
    assert_equal "Test Post", @post.title
  end

  test "author can edit their own post" do
    post sign_in_path, params: { email: "test@example.com", password: "password123" }

    patch post_path(@post), params: { post: { title: "Updated" } }
    assert_redirected_to @post
    @post.reload
    assert_equal "Updated", @post.title
  end
end
```

---

## Fase 3 — Categorías

### Objetivo
Clasificar posts en una o más categorías. Relación muchos a muchos.

### Gem Adicional

```ruby
# No se necesita gem extra — Rails maneja HABTM con Active Record
```

### Generadores

```bash
bin/rails generate model Category name:string slug:string:uniq
bin/rails generate migration CreateJoinTablePostCategory posts categories
```

### Migraciones

```ruby
# db/migrate/xxxxxx_create_categories.rb
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :categories, :slug, unique: true
    add_index :categories, :name, unique: true
  end
end

# db/migrate/xxxxxx_create_join_table_post_category.rb
class CreateJoinTablePostCategory < ActiveRecord::Migration[8.1]
  def change
    create_join_table :posts, :categories do |t|
      t.index [:post_id, :category_id]
      t.index [:category_id, :post_id]
    end
  end
end
```

### Modelos

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  has_and_belongs_to_many :posts

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug

  private

  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end
end

# app/models/post.rb (modificar)
class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_and_belongs_to_many :categories

  # ...validaciones existentes
end
```

### Controller

```ruby
# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  def index
    @categories = Category.all.order(:name)
  end

  def show
    @category = Category.find_by!(slug: params[:id])
    @posts = @category.posts.includes(:user).order(created_at: :desc)
  end
end
```

### Filtro en PostsController

```ruby
# Agregar a index
def index
  @posts = Post.includes(:user, :categories).order(created_at: :desc)
  @posts = @posts.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
end
```

### Rutas

```ruby
resources :categories, only: [:index, :show], param: :slug
```

### Formulario de Post (modificar)

```erb
<!-- Agregar a _form.html.erb -->
<div>
  <%= form.label :category_ids, "Categories", class: "block text-sm font-medium leading-6 text-gray-900" %>
  <div class="mt-2 flex flex-wrap gap-2">
    <%= form.collection_check_boxes :category_ids, Category.order(:name), :id, :name do |b| %>
      <label class="inline-flex items-center gap-1.5">
        <%= b.check_box class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600" %>
        <span class="text-sm text-gray-700"><%= b.text %></span>
      </label>
    <% end %>
  </div>
</div>
```

### Strong Params (modificar)

```ruby
def post_params
  params.require(:post).permit(:title, :body, :published, :image, category_ids: [])
end
```

### Vista Categories

```erb
<!-- app/views/categories/index.html.erb -->
<h1>Categories</h1>
<div class="flex flex-wrap gap-2">
  <% @categories.each do |cat| %>
    <%= link_to category_path(cat.slug), class: "..." do %>
      <%= cat.name %> (<%= cat.posts.count %>)
    <% end %>
  <% end %>
</div>

<!-- app/views/categories/show.html.erb -->
<h1><%= @category.name %></h1>
<!-- Reusar grid de posts del index -->
```

### Archivos a Crear/Modificar

| Archivo | Acción |
|---------|--------|
| `app/models/category.rb` | Crear |
| `app/models/post.rb` | Agregar `has_and_belongs_to_many :categories` |
| `app/controllers/categories_controller.rb` | Crear |
| `app/controllers/posts_controller.rb` | Agregar filtro category |
| `app/views/categories/index.html.erb` | Crear |
| `app/views/categories/show.html.erb` | Crear |
| `app/views/posts/_form.html.erb` | Agregar checkbox de categorías |
| `app/views/layouts/application.html.erb` | Agregar link de categorías al nav |
| `config/routes.rb` | Agregar `resources :categories` |
| `db/migrate/xxx_create_categories.rb` | Crear |
| `db/migrate/xxx_create_join_table_post_category.rb` | Crear |
| `db/seeds.rb` | Crear categorías de ejemplo |

### Seeds

```ruby
# db/seeds.rb
categories = ["Technology", "Lifestyle", "Travel", "Food", "Health", "Business"]
categories.each { |name| Category.find_or_create_by!(name: name) }
puts "Created #{Category.count} categories"
```

### Pruebas

```ruby
# test/models/category_test.rb
class CategoryTest < ActiveSupport::TestCase
  test "valid category" do
    category = Category.new(name: "Technology")
    assert category.valid?
  end

  test "requires name" do
    category = Category.new(name: nil)
    assert_not category.valid?
  end

  test "requires unique name" do
    Category.create!(name: "Tech")
    duplicate = Category.new(name: "Tech")
    assert_not duplicate.valid?
  end

  test "generates slug from name" do
    category = Category.create!(name: "My Category")
    assert_equal "my-category", category.slug
  end

  test "has many posts through join table" do
    category = Category.create!(name: "Tech")
    user = User.create!(email: "t@t.com", name: "T", password: "password123")
    post = user.posts.create!(title: "Test", body: "Body")
    category.posts << post
    assert_includes category.posts, post
  end
end
```

---

## Fase 4 — Comentarios

### Objetivo
Users autenticados pueden comentar en posts. Comentarios con autor y timestamp.

### Generadores

```bash
bin/rails generate model Comment body:text user:references post:references
```

### Migración

```ruby
# db/migrate/xxxxxx_create_comments.rb
class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.timestamps
    end
    add_index :comments, [:post_id, :created_at]
  end
end
```

### Modelos

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :body, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit do
    broadcast_append_to "post_#{post_id}_comments",
      target: "comments_list",
      partial: "comments/comment",
      locals: { comment: self }
  end
end

# app/models/post.rb (modificar)
class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_and_belongs_to_many :categories
  has_many :comments, dependent: :destroy

  # ...resto existente
end
```

### Controller

```ruby
# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :require_login

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @post, notice: "Comment posted."
    else
      redirect_to @post, alert: "Comment could not be saved."
    end
  end

  def destroy
    @post = Post.find(params[:post_id])
    @comment = @post.comments.find(params[:id])

    if @comment.user == Current.user || @post.user == Current.user
      @comment.destroy
      redirect_to @post, notice: "Comment deleted."
    else
      redirect_to @post, alert: "Not authorized."
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
```

### Rutas

```ruby
# config/routes.rb
resources :posts do
  resources :comments, only: [:create, :destroy]
end
```

### Vista de Comentarios

```erb
<!-- app/views/posts/show.html.erb — agregar al final del article -->

<!-- Sección de comentarios -->
<section class="mt-8">
  <h2 class="text-xl font-bold text-gray-900 mb-6">
    Comments (<%= @post.comments.count %>)
  </h2>

  <!-- Formulario de comentario -->
  <% if Current.user %>
    <%= form_with(model: [@post, Comment.new], class: "mb-8") do |f| %>
      <div>
        <%= f.text_area :body, rows: 3, placeholder: "Write a comment...",
              class: "block w-full rounded-md border-0 py-1.5 px-3 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm" %>
      </div>
      <div class="mt-2 flex justify-end">
        <%= f.submit "Post Comment", class: "rounded-md bg-indigo-600 px-3.5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500" %>
      </div>
    <% end %>
  <% else %>
    <p class="text-sm text-gray-500 mb-8">
      <%= link_to "Sign in", sign_in_path, class: "text-indigo-600 font-medium" %> to leave a comment.
    </p>
  <% end %>

  <!-- Lista de comentarios -->
  <div id="comments_list" class="space-y-6">
    <%= render partial: "comments/comment", collection: @post.comments.recent, as: :comment %>
  </div>
</section>
```

```erb
<!-- app/views/comments/_comment.html.erb -->
<div class="flex gap-4">
  <div class="shrink-0">
    <div class="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
      <span class="text-sm font-medium text-indigo-700">
        <%= comment.user.name.first.upcase %>
      </span>
    </div>
  </div>
  <div class="flex-1">
    <div class="flex items-center gap-2 mb-1">
      <span class="text-sm font-semibold text-gray-900"><%= comment.user.name %></span>
      <span class="text-xs text-gray-500"><%= time_ago_in_words(comment.created_at) %> ago</span>
    </div>
    <p class="text-sm text-gray-700"><%= comment.body %></p>
    <% if Current.user == comment.user || Current.user == comment.post.user %>
      <%= button_to "Delete", post_comment_path(comment.post, comment),
            method: :delete, data: { confirm: "Delete this comment?" },
            class: "text-xs text-red-600 hover:text-red-500 mt-1" %>
    <% end %>
  </div>
</div>
```

### Archivos a Crear/Modificar

| Archivo | Acción |
|---------|--------|
| `app/models/comment.rb` | Crear |
| `app/models/post.rb` | Agregar `has_many :comments` |
| `app/controllers/comments_controller.rb` | Crear |
| `app/views/comments/_comment.html.erb` | Crear |
| `app/views/posts/show.html.erb` | Agregar sección de comentarios |
| `config/routes.rb` | Anidar comments bajo posts |

### Pruebas

```ruby
# test/models/comment_test.rb
class CommentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "c@c.com", name: "Commenter", password: "password123")
    @post = @user.posts.create!(title: "Test", body: "Body")
  end

  test "valid comment" do
    comment = Comment.new(body: "Nice post!", user: @user, post: @post)
    assert comment.valid?
  end

  test "requires body" do
    comment = Comment.new(body: nil, user: @user, post: @post)
    assert_not comment.valid?
  end

  test "body max 1000 characters" do
    comment = Comment.new(body: "x" * 1001, user: @user, post: @post)
    assert_not comment.valid?
  end

  test "destroying post destroys comments" do
    @post.comments.create!(body: "Comment", user: @user)
    assert_difference("Comment.count", -1) { @post.destroy }
  end
end

# test/controllers/comments_controller_test.rb
class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "t@t.com", name: "T", password: "password123")
    @post = @user.posts.create!(title: "Test", body: "Body")
  end

  test "unauthenticated user cannot comment" do
    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: { comment: { body: "Great!" } }
    end
    assert_redirected_to sign_in_path
  end

  test "authenticated user can comment" do
    post sign_in_path, params: { email: "t@t.com", password: "password123" }
    assert_difference("Comment.count", 1) do
      post post_comments_path(@post), params: { comment: { body: "Great!" } }
    end
    assert_redirected_to @post
  end
end
```

---

## Fase 5 — Paginación y Búsqueda

### Objetivo
Paginar listas largas y permitir buscar posts por título o contenido.

### Gem

```ruby
# Agregar a Gemfile
gem "pagy", "~> 9.0"
```

### Instalación

```bash
bundle add pagy
```

Configurar en ApplicationController:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pagy::Backend
  # ... resto
end
```

### Paginación en PostsController

```ruby
def index
  posts = Post.includes(:user, :categories).order(created_at: :desc)
  posts = posts.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
  @pagy, @posts = pagy(posts, items: 12)
end
```

### Helper de Vista

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include Pagy::Frontend
end
```

### Vista Index Paginada

```erb
<!-- Reemplazar el grid y agregar paginación -->
<% if @posts.any? %>
  <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
    <% @posts.each do |post| %>
      <!-- card existente -->
    <% end %>
  </div>

  <div class="mt-8">
    <%== pagy_nav(@pagy) %>
  </div>
<% else %>
  <!-- empty state existente -->
<% end %>
```

### Búsqueda — Modelo con Scopes

```ruby
# app/models/post.rb
scope :search, ->(query) {
  where("title LIKE :q OR body LIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
}
```

### Búsqueda en Controller

```ruby
def index
  posts = Post.includes(:user, :categories).order(created_at: :desc)
  posts = posts.search(params[:q]) if params[:q].present?
  posts = posts.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
  @pagy, @posts = pagy(posts, items: 12)
end
```

### Barra de Búsqueda en la Vista

```erb
<!-- app/views/posts/index.html.erb — agregar arriba del grid -->
<%= form_tag posts_path, method: :get, class: "mb-6" do %>
  <div class="flex gap-2">
    <%= text_field_tag :q, params[:q], placeholder: "Search posts...",
          class: "flex-1 rounded-md border-0 py-2 px-3 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm" %>
    <%= submit_tag "Search", class: "rounded-md bg-white px-3.5 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50" %>
    <% if params[:q].present? %>
      <%= link_to "Clear", posts_path, class: "rounded-md bg-white px-3.5 py-2 text-sm font-semibold text-gray-600 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50" %>
    <% end %>
  </div>
<% end %>
```

### Archivos a Crear/Modificar

| Archivo | Acción |
|---------|--------|
| `Gemfile` | Agregar `gem "pagy"` |
| `app/controllers/application_controller.rb` | Include Pagy::Backend |
| `app/helpers/application_helper.rb` | Include Pagy::Frontend |
| `app/controllers/posts_controller.rb` | Agregar pagy + search |
| `app/models/post.rb` | Agregar scope :search |
| `app/views/posts/index.html.erb` | Agregar barra de búsqueda + paginación |

### Pruebas

```ruby
# test/controllers/posts_controller_test.rb (agregar)
test "search filters posts by title" do
  user = User.create!(email: "s@s.com", name: "S", password: "password123")
  user.posts.create!(title: "Ruby Tips", body: "Content")
  user.posts.create!(title: "Python Guide", body: "Content")

  get posts_path(q: "Ruby")
  assert_response :success
  assert_select "h2", count: 1
end

test "pagination works" do
  user = User.create!(email: "p@p.com", name: "P", password: "password123")
  15.times { |i| user.posts.create!(title: "Post #{i}", body: "Body") }

  get posts_path
  assert_response :success
  assert_select ".grid > div", count: 12  # items per page
end

test "search with no results shows empty state" do
  get posts_path(q: "nonexistent")
  assert_response :success
end
```

---

## Resumen de Dependencias entre Fases

```
Fase 1 (Auth)
  │
  ├──→ Fase 2 (Autoría) ──→ Fase 3 (Categorías) ──→ Fase 4 (Comentarios)
  │                                                              │
  └────────────────────────────────────────────────────→ Fase 5 (Paginación + Búsqueda)
```

### Orden de ejecución

1. **Fase 1** — Sin dependencias. Crear Users, Sessions, Registrations.
2. **Fase 2** — Depende de Fase 1. Agregar user_id a posts.
3. **Fase 3** — Independiente técnicamente, pero mejor después de Fase 2.
4. **Fase 4** — Depende de Fase 1. Comments necesitan users.
5. **Fase 5** — Independiente. Paginar index de posts y comentarios.

### Gemas a Instalar (todas las fases)

| Gem | Fase | Uso |
|-----|------|-----|
| `bcrypt` | 1 | Password hashing |
| `pagy` | 5 | Paginación |

> No se necesitan gems externas para auth, categorías o comentarios.

### Commandos de Instalación

```bash
# Fase 1
bundle add bcrypt
bin/rails generate authentication

# Fase 5
bundle add pagy
```

---

## Convenciones del Proyecto

### Estructura deArchivos
- Controllers en `app/controllers/`
- Models en `app/models/`
- Views en `app/views/{resource}/`
- Partials nombrados con `_` prefix
- Migraciones timestamped

### Testing
- Framework: Minitest (incluido en Rails)
- Unit tests en `test/models/`
- Controller tests en `test/controllers/`
- Fixtures en `test/fixtures/`
- Ejecutar: `bin/rails test`

### Estilos
- Tailwind CSS para todos los estilos
- Clases utilitarias inline en ERB
- Componentes reutilizables via partials
- Consistencia: colores indigo (primary), red (danger), green (success)

### Seguridad
- Strong parameters en todos los controllers
- Autenticación antes de acciones destructivas
- Autorización antes de editar/borrar (solo dueño)
- CSRF protection (automático en Rails)
- Sanitización de inputs (automático en ActiveRecord)
