require "rails_helper"

RSpec.describe "Instagram Messaging", type: :request do
  let(:params) do
    {
      "object"=>"instagram",
      "entry"=>[
        {
          "time"=>1731261732963,
          "id"=>"17841470242466791",
          "messaging"=>[
            {
              "sender"=>{
                "id"=>"504664759221752"
              }, "recipient"=>{
                "id"=>"17841470242466791"
              },
              "timestamp"=>1731261730927,
              "message"=>{
                "mid"=>"aWdfZAG1faXRlbToxOklHTWVzc2FnZAUlEOjE3ODQxNDcwMjQyNDY2NzkxOjM0MDI4MjM2Njg0MTcxMDMwMTI0NDI1OTY0NzU3ODIyMTIyMDE1NjozMTkzNjE0MjA3NTAzMTkyNjI1NzI3Mzc0NTI1NDEyMTQ3MgZDZD",
                "text"=>"Hello"
              }
            }
          ]
        }
      ]
    }
  end

  it "receives and sends messages", :vcr do
    allow(Instagram).to receive(:send_message)

    post api_webhooks_instagram_path(params: params)

    user = User.last
    expect(response).to be_successful
    expect(user.instagram_id).to eq("504664759221752")
    expect(user.messages.count).to eq(2)
    expect(Instagram).to have_received(:send_message).with("504664759221752", user.prompts.welcome_message)
  end
end
