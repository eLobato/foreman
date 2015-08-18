module CommonParametersHelper
  # Return true if user is authorized for controller/action OR controller/action@type, otherwise false
  # third argument may be specific object (usually for edit and destroy actions)
  def authorized_via_my_scope(controller, action, object = nil)
    authorized_for(:controller => controller, :action => action, :auth_object => object)
  end

  def parameters_title
    _("Parameters that would be associated with hosts in this %s") % (type)
  end

  def parameter_value_field(value, name)
    source_name = value[:source_name] ? "(#{value[:source_name]})" : nil
    content_tag(:div, :class => "form-group condensed") do
      content_tag(:div, :class => 'input-group') do
        content_tag(:span, :class => 'input-group-addon') do
          content_tag(:span, :class => "help-inline") { popover(_(""), _("<b>Source:</b> %{type} %{name}") % {:type => _(value[:source].to_s), :name => source_name})}
        end +
        text_area_tag("value_#{value[:safe_value]}", value[:safe_value], :rows => (value[:safe_value].to_s.lines.count || 1 rescue 1),
                      :class => "col-md-6 form-control", :disabled => true, :'data-hidden-value' => Parameter.hidden_value) +
        content_tag(:span, :class => 'input-group-addon') do
          fullscreen_button +
            link_to_function(icon_text('chevron-up'), "override_param(this)", :title => _("Override this value"),
                                 :'data-tag' => 'override', :class => "btn btn-sm btn-default") if authorized_via_my_scope("host_editing", "create_params") && !@host.host_parameters.map(&:name).include?(name)
        end
      end
    end
  end

  def use_puppet_default_help link_title = nil, title = _("Use Puppet default")
    popover(link_title, _("Do not send this parameter via the ENC.<br>Puppet will use the value defined in the manifest."), :title => title)
  end
end
