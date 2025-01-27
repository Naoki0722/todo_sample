class Todo < ApplicationRecord
  validates :title, presence: true

  after_initialize :set_defaults, if: :new_record?

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
  after_create_commit -> { broadcast_prepend_to("todos") }
  after_update_commit -> { broadcast_replace_to("todos") }
  after_destroy_commit -> { broadcast_remove_to("todos") }

  private

  def set_defaults
    self.completed ||= false
  end
end
