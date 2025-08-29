class AssistantService
  def initialize(assistant)
    @assistant = assistant
    @api_key = ENV['ASSISTANT_API_KEY'] || ENV['OPENAI_API_KEY']
  end

  def process_query(assistant_response)
    begin
      # Build context from project and user data
      context = build_context(assistant_response)
      
      # Create the prompt
      prompt = build_prompt(assistant_response.question, context)
      
      # Call the LLM API
      response = call_llm_api(prompt)
      
      # Update the assistant response
      assistant_response.update!(
        response: response[:content],
        status: :completed,
        completed_at: Time.current,
        metadata: {
          tokens_used: response[:tokens_used],
          model_used: response[:model],
          processing_time: Time.current - assistant_response.created_at
        }
      )

      # Broadcast the response if using ActionCable
      broadcast_response(assistant_response)

      { success: true, response: response[:content] }
    rescue => e
      Rails.logger.error "Assistant service error: #{e.message}"
      
      assistant_response.update!(
        status: :error,
        response: "I apologize, but I encountered an error while processing your question. Please try again later.",
        completed_at: Time.current,
        metadata: { error: e.message }
      )

      { success: false, error: e.message }
    end
  end

  private

  def build_context(assistant_response)
    context = {
      platform: "+A_DevAfrica - African Development Platform",
      assistant_type: @assistant.assistant_type,
      user_role: assistant_response.user.role
    }

    if assistant_response.project
      project = assistant_response.project
      context[:project] = {
        title: project.title,
        description: project.description,
        category: project.category,
        funding_goal: project.funding_goal,
        total_raised: project.total_raised,
        funding_percentage: project.funding_percentage,
        days_remaining: project.days_remaining,
        team_size: project.team.users.count,
        total_votes: project.total_votes,
        vote_score: project.vote_score
      }
    end

    context
  end

  def build_prompt(question, context)
    base_prompt = @assistant.prompt_template
    
    prompt = "#{base_prompt}\n\n"
    prompt += "Context:\n"
    prompt += "Platform: #{context[:platform]}\n"
    prompt += "Assistant Type: #{context[:assistant_type]}\n"
    prompt += "User Role: #{context[:user_role]}\n"
    
    if context[:project]
      prompt += "\nProject Information:\n"
      context[:project].each do |key, value|
        prompt += "- #{key.to_s.humanize}: #{value}\n"
      end
    end
    
    prompt += "\nUser Question: #{question}\n\n"
    prompt += "Please provide a helpful, accurate, and actionable response based on the context provided."
    
    prompt
  end

  def call_llm_api(prompt)
    # This is a simplified example using OpenAI API
    # You can adapt this for other LLM providers like Mistral
    
    require 'net/http'
    require 'json'

    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'

    request.body = {
      model: @assistant.model_name,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: @assistant.max_tokens,
      temperature: @assistant.temperature
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)

    if response.code == '200'
      {
        content: result.dig('choices', 0, 'message', 'content'),
        tokens_used: result.dig('usage', 'total_tokens'),
        model: result['model']
      }
    else
      raise "API Error: #{result['error']['message']}"
    end
  end

  def broadcast_response(assistant_response)
    # Broadcast using ActionCable if configured
    # AssistantChannel.broadcast_to(assistant_response.user, {
    #   type: 'response_ready',
    #   response: assistant_response
    # })
  end
end

