class Api::WebhooksController < ApiController
  def verify_facebook
    render json: params["hub.challenge"]
  end

  def facebook
    head :ok
  end

  def verify_instagram
    render json: params["hub.challenge"]
  end

  def instagram
    head :ok
  end
end
