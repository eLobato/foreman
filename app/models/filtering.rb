class Filtering < ActiveRecord::Base
  belongs_to :filter
  belongs_to :permission
  include AccessibleAttributes
end
