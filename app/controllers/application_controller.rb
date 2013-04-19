require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html

  protect_from_forgery

  before_filter :set_locale
 
  def set_locale
    available = Volmerius::Application.config.locales.map{|l| l.last }
    I18n.locale = params[:locale] || http_accept_language.compatible_language_from(available) || I18n.default_locale
  end
end
