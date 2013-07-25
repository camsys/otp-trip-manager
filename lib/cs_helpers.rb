module CsHelpers

    ACTION_ICONS = {
        :plan_a_trip => 'icon-bus-sign',
        :identify_places =>'icon-map-marker',
        :change_my_settings => 'icon-cog',
        :help_and_support => 'icon-question-sign'
    }

  # TODO Unclear whether this will need to be more flexible depending on how clients want to do their domains
  # may have to vary by environment
  def brand
    Rails.application.config.brand
  end

  def anonymous_user
    User.new
  end

end
