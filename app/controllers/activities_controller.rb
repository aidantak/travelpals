class ActivitiesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :set_activity, only: [:show, :edit, :update, :destroy]

  def index
    if params[:query].present?
      sql_query = "title ILIKE :query OR description ILIKE :query OR location ILIKE :query"
      @activities = Activity.where(sql_query, query: "%#{params[:query]}%").order(time: :asc)
    else
      @activities = Activity.all.order(time: :asc)
    end
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "activities/list", locals: {activities: @activities}, formats: [:html] }
    end
  end

  def map
    @activities = Activity.all.order(time: :asc)
    @activity_info = {}
    @activities.geocoded.each do |activity|
      @activity_info[activity.title.gsub(" ", "-")] = {
        center: [ activity.longitude, activity.latitude ],
        zoom: 10
      }
    end

    @markers = @activities.geocoded.map { |activity|
      { lat: activity.latitude,
        lng: activity.longitude,
        info_window_html: render_to_string(partial: "info_window", locals: {activity: activity})
      }
    }

  end

  def show
    @activity = Activity.find(params[:id])
    @comment = Comment.new
    @already_booked = Booking.where(activity: @activity, user: current_user).any?
    @booking = Booking.new
    @activities = Activity.where(id: params[:id])
    @markers = @activities.geocoded.map do |activity|
      {
        lat: activity.latitude,
        lng: activity.longitude
      }
    end
    if @already_booked
      @booking = Booking.find_by(activity: @activity, user: current_user)
    end
  end

  def new
    @activity = Activity.new
    @user = current_user
  end

  def create
    @activity = Activity.new(activity_params)
    @user = current_user
    @activity.user = @user
    if @activity.save
      redirect_to activity_path(@activity)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update

    if @activity.update(activity_params)
        redirect_to activity_path(@activity)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy
    redirect_to activities_path, status: :see_other, alert: "Activity deleted"
  end

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :location, :latitude, :longitude, :time, photos: [])
  end
end
