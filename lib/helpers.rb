require 'sinatra/base'

class Object

  # An object is blank if it's false, empty, or a whitespace string.
  # For example, "", "   ", +nil+, [], and {} are blank.
  #
  # This simplifies:
  #
  #   if !address.nil? && !address.empty?
  #
  # ...to:
  #
  #   if !address.blank?
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

module Sinatra

  module TidalHelper
    def h(text)
      Rack::Utils.escape_html(text)
    end


    def input_text(name, label, value = '', size = nil)
      "<li><label for=\"#{name}\">#{label}</label>" +
              "<input id=\"#{name}\" name=\"#{name}\" type=\"text\" value=\"#{value}\"#{size ? " size=\"#{size}\"" : ''}/><li>"
    end

    def input_checkbox(name, label, value = false)
      "<li><label for=\"#{name}\">#{label}</label>" +
              "<input name=\"#{name}\" type=\"checkbox\"#{value ? ' checked="checked"' : ''}\"/></li>"
    end

    def input_combobox(name, label, possible_values, selected_value = nil)
      "<li><label for=\"#{name}\">#{label}</label>" +
              "<select name=\"#{name}\">#{input_select_content(possible_values, selected_value)}</select></li>"
    end

    def input_select_content possible_values, selected_value = nil
      possible_values.collect { |key, value| "<option value=\"#{value}\"#{(value == selected_value) ? ' selected="selected' : ''}>#{key}</option>" }.join('')
    end

    def display_feeds_select feeds, id = nil
      r = "<li><label for=\"feed\">Feed</label> <select name=\"feed\"#{id ? "id=\"#{id}\"" : ''}>"
      current_category = nil
      feeds.each do |feed|
        if feed.category != current_category
          if current_category
            r << '</optgroup>'
          end
          r << "<optgroup label=\"#{feed.category}\">"
          current_category = feed.category
        end
        r << "<option value=\"#{feed.id}\">&nbsp;#{feed.name}</option>"
      end
      if current_category
        r << '</optgroup>'
      end
      r << '</select></li>'
    end

    def display_date_time date, between = ''
      if date
        date.strftime("%d/%m/%Y #{between}%H:%M:%S")
      end
    end


  end

  helpers TidalHelper

end
