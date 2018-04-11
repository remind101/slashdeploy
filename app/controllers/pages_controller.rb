# Controller for static pages
class PagesController < ApplicationController
  skip_before_action :authenticate!

  def index
  end
end
