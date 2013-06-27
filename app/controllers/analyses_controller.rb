class AnalysesController < ApplicationController
  # GET /analyses
  # GET /analyses.json
  def index
    @analyses = Analysis.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @analyses }
    end
  end

  # GET /analyses/1
  # GET /analyses/1.json
  def show
    @analysis = Analysis.find(params[:id])
    if (@analysis.processed and !@analysis.failed and @analysis.listings.count > 3)
      redirect_to listings_path(analysis_id: @analysis.id)
      return
    end

    @segments = @analysis.get_segments if (@analysis.processed and !@analysis.failed and @analysis.listings.count > 3)
    @overview = @analysis.get_overview if (@analysis.processed and !@analysis.failed and @analysis.listings.count > 3)
    @body_class = 'analysis-show'

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @analysis }
    end
  end

  def poll
    @analysis = Analysis.find(params[:id])
    if @analysis.processed
      render text: '1'
    elsif @analysis.failed
      render text: '-1'
    else
      render text: '0'
    end
  end

  # GET /analyses/home
  # GET /analyses/home.json
  def home
    @analysis = Analysis.new
    @analysis.bedrooms = params[:bedrooms] if params[:bedrooms]
    @analysis.address = params[:address] if params[:address]

    @body_class = 'homepage-body'

    respond_to do |format|
      format.html { render layout: 'home' }
      format.json { render json: @analysis }
    end
  end

  # GET /analyses/new
  # GET /analyses/new.json
  def new
    @analysis = Analysis.new(params[:analysis])
    if params[:tags]
      @analysis.tags = params[:tags].select{|k,v| v == "1"}.keys.join(',')
    end
    p @analysis.tags

    respond_to do |format|
      if @analysis.valid?
        format.html # new.html.erb
        format.json { render json: @analysis }
        format.pdf {
          render :pdf => "new.pdf"
        }
      else
        format.html { 
          @body_class = 'homepage-body'
          render action: "home", layout: "home" 
        }
        format.json { render json: @analysis.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /analyses/1/edit
  def edit
    @analysis = Analysis.find(params[:id])
  end

  # POST /analyses
  # POST /analyses.json
  def create
    @analysis = Analysis.new(params[:analysis])

    respond_to do |format|
      if @analysis.save
        format.html { redirect_to @analysis, notice: 'Analysis was successfully created.' }
        format.json { render json: @analysis, status: :created, location: @analysis }
      else
        format.html { render action: "new" }
        format.json { render json: @analysis.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /analyses/1
  # PUT /analyses/1.json
  def update
    @analysis = Analysis.find(params[:id])

    respond_to do |format|
      if @analysis.update_attributes(params[:analysis])
        format.html { redirect_to @analysis, notice: 'Analysis was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @analysis.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /analyses/1
  # DELETE /analyses/1.json
  def destroy
    @analysis = Analysis.find(params[:id])
    @analysis.destroy

    respond_to do |format|
      format.html { redirect_to analyses_url }
      format.json { head :no_content }
    end
  end
end
