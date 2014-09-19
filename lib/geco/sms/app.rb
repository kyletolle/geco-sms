require 'sinatra/base'
require 'fulcrum'
require 'twilio-ruby'

class Geco
  class Sms
    class App < Sinatra::Base
      require 'json'

      # Idea from http://www.recursion.org/2011/7/21/modular-sinatra-foreman
      configure do
        set :app_file, __FILE__
        set :port, ENV['PORT']
      end

      post '/' do
        request.body.rewind
        post_body = request.body.read

        payload = JSON.parse post_body

        is_record_create = payload['type'] == 'record.create'
        return unless is_record_create

        has_payload_data = payload['data']
        return unless has_payload_data

        form_id = payload['data']['form_id']

        is_form_we_want = form_id == expected_form_id
        return unless is_form_we_want

        record_id = payload['data']['id']

        phone_numbers.each do |number|
          next if number.blank?
          send_text(number, "New GeCo 2014 Happening: #{url_to_send(record_id)}")
        end
      end

    private
      def api
        @api ||= Fulcrum::Client.new api_key
      end

      def api_key
        ENV['SMS_FULCRUM_API_KEY']
      end

      def expected_form_id
        ENV['SMS_FULCRUM_FORM_ID']
      end

      def alert_form_id
        ENV['SMS_FULCRUM_ALERTS_FORM_ID']
      end

      def url_to_send(record_id)
        url_base+record_id
      end

      def url_base
        'http://geco.herokuapp.com/?record_id='
      end

      def phone_numbers
        records_of_people_to_alert.map{|r| r['form_values'][phone_number_field_key]}
      end

      def phone_number_field_key
        ENV['SMS_FULCRUM_PHONE_NUMBER_FIELD_KEY']
      end

      def records_of_people_to_alert
        api.records.all(form_id: alert_form_id).objects
      end

      def twilio_sid
        ENV['SMS_TWILIO_SID']
      end

      def twilio_token
        ENV['SMS_TWILIO_TOKEN']
      end

      def twilio_number
        ENV['SMS_TWILIO_NUMBER']
      end

      def send_text(number, message)
        @twilio_client ||=
          Twilio::REST::Client.new(twilio_sid, twilio_token)

        @twilio_client.account.messages.create(
          from: twilio_number,
          to:   number,
          body: message
        )
      end

      run! if app_file == $0
    end
  end
end

