# Rails 8で作る モダンなTodoアプリケーション実装ガイド

Rails 8、Hotwire、TailwindCSSを使用して、モダンなTodoアプリケーションを作成する手順を解説します。
このチュートリアルでは、SPAのような体験を提供しながら、Railsの生産性の高さを維持する方法を学びます。

## 目次

1. [プロジェクトのセットアップ](#プロジェクトのセットアップ)
2. [モデルの作成](#モデルの作成)
3. [コントローラーの実装](#コントローラーの実装)
4. [ビューの作成](#ビューの作成)
5. [Hotwireの設定](#hotwireの設定)
6. [スタイリングの適用](#スタイリングの適用)

## プロジェクトのセットアップ

まず、新しいRailsプロジェクトを作成します。Rails 8では、TailwindCSSのサポートが組み込まれているため、`--css`オプションで簡単に設定できます。

```bash
rails new todo_app --css tailwind --database=sqlite3
cd todo_app
```

## モデルの作成

Todoモデルを作成します。title、description、completedの3つの属性を持たせます。

```bash
rails generate model Todo title:string description:text completed:boolean
rails db:migrate
```

モデルにバリデーションと便利なスコープを追加します：

```ruby
# app/models/todo.rb
class Todo < ApplicationRecord
  validates :title, presence: true

  after_initialize :set_defaults, if: :new_record?

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }

  private

  def set_defaults
    self.completed ||= false
  end
end
```

## コントローラーの実装

TodosコントローラーにCRUD操作とTurbo Streamsのサポートを実装します：

```ruby
# app/controllers/todos_controller.rb
class TodosController < ApplicationController
  before_action :set_todo, only: [:show, :edit, :update, :destroy]

  def index
    @todos = Todo.order(created_at: :desc)
    @todo = Todo.new
  end

  def create
    @todo = Todo.new(todo_params)

    respond_to do |format|
      if @todo.save
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("todos", partial: "todos/todo", locals: { todo: @todo }) }
        format.html { redirect_to todos_path, notice: "Todoが作成されました。" }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("todo_form", partial: "todos/form", locals: { todo: @todo }) }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @todo.update(todo_params)
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@todo, partial: "todos/todo", locals: { todo: @todo }) }
        format.html { redirect_to todos_path, notice: "Todoが更新されました。" }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("todo_#{@todo.id}", partial: "todos/todo", locals: { todo: @todo }) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @todo.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@todo) }
      format.html { redirect_to todos_path, notice: "Todoが削除されました。" }
    end
  end

  private

  def set_todo
    @todo = Todo.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :description, :completed)
  end
end
```

## ビューの作成

### インデックスページ

```erb
# app/views/todos/index.html.erb
<div class="max-w-4xl mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-8">Todos</h1>

  <%= turbo_frame_tag "todo_form" do %>
    <div class="bg-white shadow-sm rounded-lg p-6 mb-8">
      <h2 class="text-xl font-semibold mb-4">新しいTodoを作成</h2>
      <%= render "form", todo: @todo %>
    </div>
  <% end %>

  <div class="bg-white shadow-sm rounded-lg">
    <div class="p-6">
      <h2 class="text-xl font-semibold mb-4">Todo一覧</h2>
      <%= turbo_frame_tag "todos" do %>
        <div class="space-y-4">
          <%= render @todos %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

### フォームパーシャル

```erb
# app/views/todos/_form.html.erb
<%= form_with(model: todo, class: "space-y-4") do |form| %>
  <% if todo.errors.any? %>
    <div class="bg-red-50 p-4 rounded-lg">
      <div class="text-red-700 font-medium">
        <%= pluralize(todo.errors.count, "個のエラー") %>が発生しました:
      </div>
      <ul class="list-disc list-inside text-red-600">
        <% todo.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :title, "タイトル", class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= form.text_field :title, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
  </div>

  <div>
    <%= form.label :description, "説明", class: "block text-sm font-medium text-gray-700 mb-1" %>
    <%= form.text_area :description, rows: 3, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" %>
  </div>

  <div class="flex items-center">
    <%= form.check_box :completed, class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" %>
    <%= form.label :completed, "完了", class: "ml-2 block text-sm text-gray-700" %>
  </div>

  <div class="flex justify-end">
    <%= form.submit "保存", class: "inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" %>
  </div>
<% end %>
```

### Todoパーシャル

```erb
# app/views/todos/_todo.html.erb
<%= turbo_frame_tag todo do %>
  <div class="bg-white border rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200">
    <div class="p-4">
      <div class="flex items-start justify-between">
        <div class="flex items-start space-x-3 flex-grow">
          <%= form_with(model: todo, class: "flex items-center") do |form| %>
            <%= form.check_box :completed,
                class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500",
                onchange: "this.form.requestSubmit()" %>
          <% end %>

          <div class="flex-grow">
            <h3 class="text-lg font-medium <%= todo.completed? ? 'line-through text-gray-500' : 'text-gray-900' %>">
              <%= todo.title %>
            </h3>
            <p class="mt-1 text-sm text-gray-500">
              <%= todo.description %>
            </p>
          </div>
        </div>

        <div class="flex items-center space-x-2 ml-4">
          <%= link_to edit_todo_path(todo),
              class: "text-gray-400 hover:text-gray-500",
              data: { turbo_frame: "modal" } do %>
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
          <% end %>

          <%= button_to todo_path(todo),
              method: :delete,
              class: "text-gray-400 hover:text-red-500",
              data: { turbo_confirm: "このTodoを削除してもよろしいですか？" } do %>
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          <% end %>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

## Hotwireの設定

Hotwireは既にRails 8にデフォルトで含まれていますが、フラッシュメッセージの自動消去などの追加機能を実装するために、Stimulusコントローラーを作成します：

```javascript
// app/javascript/controllers/removable_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  remove() {
    this.containerTarget.remove()
  }
}
```

## スタイリングの適用

アプリケーション全体のレイアウトを設定し、TailwindCSSのユーティリティクラスを活用します：

```erb
# app/views/layouts/application.html.erb
<!DOCTYPE html>
<html class="h-full bg-gray-50">
  <head>
    <title>TodoMorph</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="h-full">
    <div class="min-h-full">
      <nav class="bg-indigo-600">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="flex h-16 items-center justify-between">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <h1 class="text-white text-xl font-bold">TodoMorph</h1>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <% if notice.present? %>
        <div class="bg-green-50 p-4" data-controller="removable" data-removable-target="container">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-green-800"><%= notice %></p>
            </div>
          </div>
        </div>
      <% end %>

      <main>
        <div class="mx-auto max-w-7xl py-6 sm:px-6 lg:px-8">
          <%= yield %>
        </div>
      </main>

      <%= turbo_frame_tag "modal" %>
    </div>
  </body>
</html>
```

## 実装のポイント

### 1. Hotwireの活用

- Turbo Framesを使用して、フォームの送信やTodoの更新をページ遷移なしで実現
- Turbo Streamsで、Todo作成時のリアルタイム更新を実装
- Stimulusコントローラーでフラッシュメッセージの自動消去機能を実装

### 2. TailwindCSSの活用

- コンポーネントベースのデザインを実現
- レスポンシブデザインの実装
- ホバーエフェクトやトランジションの追加

### 3. UXの改善

- フォームのバリデーションエラーをインライン表示
- 削除時の確認ダイアログ
- 完了状態の視覚的なフィードバック

## まとめ

このチュートリアルでは、Rails 8の新機能とHotwire、TailwindCSSを組み合わせて、
モダンでインタラクティブなTodoアプリケーションを作成しました。

特に以下の点に注目してください：

1. Hotwireによる非同期更新で、SPAのような体験を実現
2. TailwindCSSによる美しいUIデザイン
3. Stimulusを使用した動的な機能の実装
4. Rails 8の新機能の活用

これらの技術を組み合わせることで、JavaScriptフレームワークを使用せずに、
モダンでインタラクティブなWebアプリケーションを構築できることが分かりました。
