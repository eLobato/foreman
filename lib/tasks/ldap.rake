desc <<-END_DESC
Refreshes LDAP usergroups. It adds to an LDAP usergroup all the foreman users that belong to it, and removes foreman users
in that usergroup that do not belong in LDAP anymore.
END_DESC

namespace :ldap do
  task :refresh_usergroups => :environment do
    Usergroup.select { |ug| ug.auth_source.is_a?(AuthSourceLdap) }.each do |ug|
      begin
      ug.refresh_ldap
      rescue
        puts "User group #{ug} could not be refreshed - LDAP source #{ug.auth_source} not available"
      end
    end
  end
end

