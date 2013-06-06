class ListingComparisonsController < ApplicationController
  # GET /listing_comparisons
  # GET /listing_comparisons.json
  def index
    @address_weight = @bedrooms_weight = @location_weight = @price_weight = @cutoff = 1
    if params[:options] 
      @address_weight =  params[:options][:address_weight]
      @bedrooms_weight =  params[:options][:bedrooms_weight]
      @location_weight =  params[:options][:location_weight]
      @price_weight =  params[:options][:price_weight]
      @cutoff =  params[:options][:cutoff]
      Listing.generate_all_comparisons(params[:options])
    end

    @listing_comparisons = ListingComparison.order(:score).all
    
#  @false_positive = (ListingComparison.where("score <= ? AND duplicate == ?", @cutoff, -1).count * 100) / ListingComparison.all.count
# @false_negative = (ListingComparison.where("score > ? AND duplicate == ?", @cutoff, 1).count * 100) / ListingComparison.all.count

  @false_positive = ListingComparison.where("score <= ? AND duplicate == ?", @cutoff, -1).count
 @false_negative = ListingComparison.where("score > ? AND duplicate == ?", @cutoff, 1).count
  

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @listing_comparisons }
    end
  end

  # GET /listing_comparisons/1
  # GET /listing_comparisons/1.json
  def show

    @listing_comparison = ListingComparison.find(params[:id])
  
    @l1 = @listing_comparison.listing_1
    @l2 = @listing_comparison.listing_2

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @listing_comparison }
    end
  end

  # PUT /listing_comparisons/1
  # PUT /listing_comparisons/1.json
  def update
    p 1
    @listing_comparison = ListingComparison.find(params[:id])
    p 2

    respond_to do |format|
      if @listing_comparison.update_attributes(params[:listing_comparison])
        p 3
        format.html { redirect_to @listing_comparison, notice: 'Listing comparison was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @listing_comparison.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /listing_comparisons/1
  # DELETE /listing_comparisons/1.json
  def destroy
    @listing_comparison = ListingComparison.find(params[:id])
    @listing_comparison.destroy

    respond_to do |format|
      format.html { redirect_to listing_comparisons_url }
      format.json { head :no_content }
    end
  end
end
