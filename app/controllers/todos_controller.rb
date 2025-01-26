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
    unless @todo.save
      render :new, status: :unprocessable_entity
    end
    @todo_count = Todo.count
  end

  def update
    unless @todo.update(todo_params)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy
    @todo_count = Todo.count
  end

  private

  def set_todo
    @todo = Todo.find(params[:id])
    @todo = Todo.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :description, :completed)
  end
end
