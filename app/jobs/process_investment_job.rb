class ProcessInvestmentJob < ApplicationJob
  queue_as :default

  def perform(investment_id, session_data = nil)
    investment = Investment.find(investment_id)
    
    Rails.logger.info "Processing investment #{investment.id} for project #{investment.project.title}"

    begin
      # Update investment status
      investment.update!(
        status: :confirmed,
        confirmed_at: Time.current
      )

      # Update project funding status
      investment.project.update_status_based_on_funding!

      # Send confirmation email to investor
      UserMailer.investment_confirmed(investment).deliver_now

      # Send notification to project team
      UserMailer.new_investment_notification(investment).deliver_now

      # Log the successful processing
      Rails.logger.info "Successfully processed investment #{investment.id}"

      # Schedule escrow release job if project is fully funded
      if investment.project.fully_funded?
        ReleaseEscrowJob.set(wait: 1.day).perform_later(investment.project.id)
      end

    rescue => e
      Rails.logger.error "Failed to process investment #{investment.id}: #{e.message}"
      
      # Update investment status to indicate processing failure
      investment.update!(
        status: :cancelled,
        failure_reason: "Processing failed: #{e.message}"
      )

      # Notify relevant parties about the failure
      UserMailer.investment_processing_failed(investment).deliver_now
      
      raise e
    end
  end
end

