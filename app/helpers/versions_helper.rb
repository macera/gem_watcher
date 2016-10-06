module VersionsHelper

  def alert_icon(color)
    if color.present?
      content_tag(:i, '', class: "warning sign icon #{color}")
    end
  end

end
