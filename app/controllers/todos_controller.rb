class TodosController < ApplicationController
  before_action :set_todo, only: [:show, :edit, :update, :destroy]

  def index
    @todos = Todo.order(created_at: :desc)
    @todo = Todo.new
  end

  def show
  end

  def new
    @todo = Todo.new
  end

  def edit
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
