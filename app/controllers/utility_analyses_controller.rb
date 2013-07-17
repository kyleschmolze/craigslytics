class UtilityAnalysesController < ApplicationController
  # before_filter :authenticate_user!

  # GET /utility_analyses
  # GET /utility_analyses.json
  def index
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @listings }
    end
  end

  # GET /utility_analyses/:id
  # GET /utility_analyses/:id.json
  def show
    @listing = Listing.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @utility_analysis }
    end
  end

end
