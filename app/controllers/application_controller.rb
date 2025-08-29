class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  protect_from_forgery with: :exception
  before_action :authenticate_user!, except: [:health]
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def health
    render json: { status: 'ok', timestamp: Time.current }
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :role, :country])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :bio, :avatar, :country, :skills, :linkedin_url, :github_url])
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end
end

