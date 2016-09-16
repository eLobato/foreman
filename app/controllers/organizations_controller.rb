class OrganizationsController < ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  include Foreman::Controller::Parameters::Organization

  # Creating an organization just involves creating a tag and
  # an empty tagging for all kind of objects it should be
  # associated with
  #
  # The empty tagging allows the Organization to show up on the list of
  # available organizations when we edit any of the tagged objects
  def create
    @tag = tag_class.new(resource_params)
    process_error(:render => "tags/new") unless @tag.valid?

    else

    end
  end

  def index
    # This should be protected by roles.
    # e.g: if use cannot see certain tags, don't show them here
    tags = ActsAsTaggableOn::Tag.includes(:taggings).
      where(taggings: { context: context } ).
      uniq(:name).order(:name)

    render 'tags/index',
      :locals => { :tags => tags.paginate(:page => params[:page]) }
  end

  def new
    @tag = tag_class.new
    render 'tags/new'
  end

  def tag_class
    controller_name.classify.constantize
  end

  def context
    controller_name
  end
end
