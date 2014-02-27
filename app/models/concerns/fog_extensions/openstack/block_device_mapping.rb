module FogExtensions
  module Openstack
    module Server
      module BlockDeviceMapping 
        class Block
          extend ActiveSupport::Concern
          attr_accessor :device_name, :delete_on_termination, :volume_id
        end
      end
    end
  end
end
