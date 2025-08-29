class AssistantQueryJob < ApplicationJob
  queue_as :default

  def perform(assistant_response_id)
    assistant_response = AssistantResponse.find(assistant_response_id)
    assistant = assistant_response.assistant

    Rails.logger.info "Processing assistant query #{assistant_response.id} for assistant #{assistant.name}"

    # Check if assistant is available
    unless assistant.active?
      assistant_response.update!(
        status: :error,
        response: "I'm currently unavailable. Please try again later.",
        completed_at: Time.current
      )
      return
    end

    # Process the query using AssistantService
    service = AssistantService.new(assistant)
    result = service.process_query(assistant_response)

    if result[:success]
      Rails.logger.info "Successfully processed assistant query #{assistant_response.id}"
    else
      Rails.logger.error "Failed to process assistant query #{assistant_response.id}: #{result[:error]}"
    end
  end
end

