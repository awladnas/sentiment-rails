class AdminController < ApplicationController
  before_action :authenticate_admin!
  def index
    @users = User.all.where.not(id: current_user)
  end

  def check_sentiments
    start = DateTime.strptime(params[:start_date] , '%m/%d/%Y').beginning_of_day
    end_date = DateTime.strptime(params[:end_date], '%m/%d/%Y').end_of_day
    user = params[:user]
    tones = get_data(start, end_date, user)
    @chart_data = []
    if tones && tones['document_tone'] && tones['document_tone']['tone_categories']
      tones['document_tone']['tone_categories'].each do |data|
        data['tones'].each do |tone_data|
          if tone_data['score'] > 0.5
            @chart_data << [tone_data['tone_name'], tone_data['score'].round(2)]
          end
        end
      end
    end
    respond_to do |format|
      format.js {render layout: false}
    end

  end

  protected

  def authenticate_admin!
    unless current_user.is_admin?
      redirect_to root_path
    end
  end


  def get_data(start, end_date, user)
    user = User.find user
    @user = user
    text = user.messages.between(start, end_date).map{|m| m.body}.join(" ")
    return nil if text.empty?
    url = 'https://gateway.watsonplatform.net/tone-analyzer/api/v3/tone?version=2016-05-19'
    auth = {:username => WATSON_USER, :password => WATSON_PASSWORD}
    result = HTTParty.post(url,
                           :body => { :text => text }.to_json,
                           :basic_auth => auth,
                           :headers => { 'Content-Type' => 'application/json' } )
    JSON.parse result.body

  end


end


