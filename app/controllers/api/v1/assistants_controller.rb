class Api::V1::AssistantsController < ApplicationController
  before_action :set_assistant, only: [:show, :ask]

  def show
    render json: {
      assistant: ActiveModelSerializers::SerializableResource.new(@assistant),
      recent_responses: ActiveModelSerializers::SerializableResource.new(
        @assistant.assistant_responses.for_user(current_user).recent.limit(10)
      )
    }
  end

  def ask
    authorize @assistant
    
    question = params[:question]
    project_id = params[:project_id]
    
    if question.blank?
      render json: { errors: ['Question cannot be blank'] }, status: :unprocessable_entity
      return
    end

    # Create assistant response record
    @response = @assistant.assistant_responses.create!(
      user: current_user,
      project_id: project_id,
      question: question,
      status: :pending
    )

    # Queue the assistant query job
    AssistantQueryJob.perform_async(@response.id)

    render json: {
      response: ActiveModelSerializers::SerializableResource.new(@response),
      message: 'Your question has been submitted. You will receive a response shortly.'
    }, status: :accepted
  end

  private

  def set_assistant
    @assistant = Assistant.find(params[:id])
  end
end

