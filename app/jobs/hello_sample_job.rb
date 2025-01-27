class HelloSampleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    pp args
  end
end
