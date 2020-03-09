# name: discourse-forum-plugin
# about: discourse forum plugin
# version: 0.1
# authors: null
# url: https://github.com/zhangml123/discourse-forum-plugin

enabled_site_setting :discourse_forum_plugin

Discourse.top_menu_items.push(:essence)
Discourse.anonymous_top_menu_items.push(:essence)
Discourse.filters.push(:essence)
Discourse.anonymous_filters.push(:essence) 

require_dependency 'topic_query'
class ::TopicQuery
  SORTABLE_MAPPING["essence"] = "custom_fields.event_start"

  def list_essence
   topics = create_list(:essence) { |l| l.where('topics.pinned_globally OR topics.pinned_until > now()').order('topics.pinned_at DESC') }
  end
end   



after_initialize do

  module ::DiscourseQrcode
    class Engine < ::Rails::Engine
      engine_name "discourse_qrcode"
      isolate_namespace DiscourseQrcode
    end
  end	
  require_dependency "application_controller"
  class DiscourseQrcode::GetQrcodeController < ::ApplicationController
  	skip_before_action :check_xhr, only: [:index]
    def index
      host = request.host
      url = params[:url]
      if url.include? host
        qrcode_svg = RQRCode::QRCode.new(url).as_svg(
          offset: 0,
          color: '000',
          shape_rendering: 'crispEdges',
          module_size: 4
        )
        html = "<div style=\"text-align:center\">" + qrcode_svg + "</div>" 
        render html: html.html_safe
      else
      	render json:{"status":false}
      end
    end
  end
  DiscourseQrcode::Engine.routes.draw do
    get "/get-qrcode" => "get_qrcode#index"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseQrcode::Engine, at: "/"
  end
end

register_css <<EOF
    #share-link .actions .sources { max-width: 50% !important; }
EOF