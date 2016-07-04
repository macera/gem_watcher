module FeedsHelper

  # 1週間以内の場合、Newラベルを表示する
  def new_label(date)
    if date > 1.weeks.ago
      content_tag(:span, class: "ui orange horizontal label") do
        'New'
      end
    end
  end

  # 3を超える場合...moreボタンを表示する
  def show_more(count ,path)
    if count > 3
      link_to(path, class: 'item') do
        content_tag(:div, class: "ui small label") do
          '...more'
        end
      end
    end
  end


end