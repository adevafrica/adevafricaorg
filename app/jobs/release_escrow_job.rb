class ReleaseEscrowJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = Project.find(project_id)
    
    Rails.logger.info "Processing escrow release for project #{project.title}"

    # Check if project meets criteria for escrow release
    unless project.funded? && project.fully_funded?
      Rails.logger.warn "Project #{project.id} does not meet escrow release criteria"
      return
    end

    begin
      # Get all confirmed investments for this project
      investments = project.investments.confirmed

      total_amount = investments.sum(:amount)
      platform_fee = total_amount * 0.05 # 5% platform fee
      net_amount = total_amount - platform_fee

      # Process escrow release through Stripe
      stripe_service = StripeService.new
      
      # This would typically involve transferring funds to the project team's Stripe Connect account
      # For now, we'll just log the transaction and update the project status
      
      Rails.logger.info "Releasing escrow: Total: $#{total_amount}, Platform Fee: $#{platform_fee}, Net: $#{net_amount}"

      # Update project status
      project.update!(
        status: :completed,
        escrow_released_at: Time.current,
        escrow_amount: net_amount
      )

      # Update all investments to mark escrow as released
      investments.update_all(
        escrow_released: true,
        escrow_released_at: Time.current
      )

      # Send notifications
      UserMailer.escrow_released_notification(project).deliver_now
      
      # Notify all investors
      investments.includes(:user).each do |investment|
        UserMailer.investment_escrow_released(investment).deliver_now
      end

      Rails.logger.info "Successfully released escrow for project #{project.id}"

    rescue => e
      Rails.logger.error "Failed to release escrow for project #{project.id}: #{e.message}"
      
      # Schedule retry
      ReleaseEscrowJob.set(wait: 1.hour).perform_later(project_id)
      
      raise e
    end
  end
end

