module VersionsHelper

  def alert_icon(status)
    case status
    when :error
      content_tag(:i, '', class: "warning sign icon red")
    when :children_error
      content_tag(:i, '', class: "warning sign icon yellow")
    end
  end



end
