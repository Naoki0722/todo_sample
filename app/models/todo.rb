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
