# frozen_string_literal: true

module Pages
  class Management < Base
    set_url '/admin'

    element :generate_link, '.generate-link > a'
    element :download_link, '.download-link > a'
    element :audit_trail_link, '#audit-trail > a'
  end
end
