module ParameterValidators
  extend ActiveSupport::Concern

  included do
    validate :validate_parameters_names
  end

  def validate_parameters_names
    names = []
    errors = false
    self.send(model_symbol).send(parameters_symbol).each do |param|
      next unless param.new_record? # normal validation would catch this
      if names.include?(param.name)
        param.errors[:name] = _('has already been taken')
        errors = true
      else
        names << param.name
      end
      self.errors[parameters_symbol] = _('Please ensure the following parameters name are unique') if errors
    end
  end

  def parameters_symbol
    self.class.to_s.tableize.to_sym
  end

  def model_symbol
    case self
    when OsParameter           then :operatingsystem
    when GroupParameter        then :hostgroup
    when OrganizationParameter then :organization
    when LocationParameter     then :location
    end
  end

end
