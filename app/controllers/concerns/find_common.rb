# This mixin is used by both ApplicationController and Api::BaseController
# Searches for an object based on its id, name, label, etc and assign it to an instance variable
# friendly_id performs the logic if params[:id] is 'id' or 'id-name' or 'name'

module FindCommon
  # example: @host = Host.find(params[:id])
  def find_resource
    instance_variable_set("@#{resource_name}", resource_finder)
  end

  def resource_finder
    raise ActiveRecord::RecordNotFound if resource_scope.empty?
    result = resource_scope.from_param(params[:id]) if resource_scope.respond_to?(:from_param)
    result ||= resource_scope.friendly.find(params[:id]) if resource_scope.respond_to?(:friendly)
    result ||= resource_scope.find(params[:id])
  end

  def resource_name(resource = controller_name)
    resource.singularize
  end

  def resource_class
    @resource_class ||= resource_class_for(resource_name)
    raise NameError, "Could not find resource class for resource #{resource_name}" if @resource_class.nil?
    @resource_class
  end

  def resource_scope(options = {})
    @resource_scope ||= scope_for(resource_class, options)
  end

  def scope_for(resource, options = {})
    controller = options.delete(:controller){ controller_name }
    # don't call the #action_permission method here, we are not sure if the resource is authorized at this point
    # calling #action_permission here can cause an exception, in order to avoid this, ensure :authorized beforehand
    permission = options.delete(:permission)

    if resource.respond_to?(:authorized)
      permission ||= "#{action_permission}_#{controller}"
      resource = resource.authorized(permission, resource)
    end

    resource.where(options)
  end

  def resource_class_for(resource)
    begin
      return resource.classify.constantize
    rescue NameError
      return nil
    end
  end
end
