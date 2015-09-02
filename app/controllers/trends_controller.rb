class TrendsController < ApplicationController
  before_filter :find_resource, :only => [:show, :edit, :update, :destroy]

  def index
    @trends = Trend.types.includes(:trendable).sort_by {|e| e.type_name.downcase }.paginate(:page => params[:page])
  end

  def new
    @trend = Trend.new
  end

  def show
    render 'trends/_empty_data' if @trend.values.joins(:trend_counters).empty?
  end

  def create
    safe_params ||= { }
    @trend = safe_params[:trendable_type] == 'FactName' ? FactTrend.new(safe_params) : ForemanTrend.new(safe_params)
    if @trend.save
      process_success
    else
      process_error
    end
  end

  def update
    @trends = Trend.update(safe_params.keys, safe_params.values).reject { |p| p.errors.empty? }
    if @trends.empty?
      process_success
    else
      process_error
    end
  end

  def edit
  end

  def destroy
    if @trend.destroy
      process_success
    else
      process_error
    end
  end

  def count
    TrendImporter.update!
    redirect_to trends_url
  end
end
