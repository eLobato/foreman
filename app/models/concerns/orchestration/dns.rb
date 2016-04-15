module Orchestration::DNS
  extend ActiveSupport::Concern

  RECORD_TYPES = [:a, :aaaa, :ptr, :ptr6]

  included do
    after_validation :dns_conflict_detected?, :queue_dns, :unless => :importing_facts
    before_destroy :queue_dns_destroy, :unless => :importing_facts
    register_rebuild(:rebuild_dns, N_('DNS'))
  end

  def dns_ready?
    # host.managed? and managed? should always come first so that orchestration doesn't
    # even get tested for such objects
    SETTINGS[:unattended] && (host.nil? || host.managed?) && managed? && hostname.present?
  end

  def dns?
    dns_ready? && ip_available? && !domain.nil? && !domain.proxy.nil?
  end

  def dns6?
    dns_ready? && ip6_available? && !domain.nil? && !domain.proxy.nil?
  end

  def reverse_dns?
    dns_ready? && ip_available? && !subnet.nil? && subnet.dns?
  end

  def reverse_dns6?
    dns_ready? && ip6_available? && !subnet6.nil? && subnet6.dns?
  end

  def rebuild_dns
    logger.info "IPv4 DNS not supported for #{name}, skipping orchestration rebuild" unless dns?
    logger.info "IPv6 DNS not supported for #{name}, skipping orchestration rebuild" unless dns6?
    logger.info "Reverse IPv4 DNS not supported for #{name}, skipping orchestration rebuild" unless reverse_dns?
    logger.info "Reverse IPv6 DNS not supported for #{name}, skipping orchestration rebuild" unless reverse_dns6?
    return true unless dns? || dns6? || reverse_dns? || reverse_dns6?
    del_dns_a_record_safe
    del_dns_aaaa_record_safe
    del_dns_ptr_record_safe
    del_dns_ptr6_record_safe
    a_record_result = true
    aaaa_record_result = true
    ptr_record_result = true
    ptr6_record_result = true
    begin
      a_record_result = recreate_a_record if dns?
      aaaa_record_result = recreate_aaaa_record if dns6?
      ptr_record_result = recreate_ptr_record if reverse_dns?
      ptr6_record_result = recreate_ptr6_record if reverse_dns6?
      a_record_result && aaaa_record_result && ptr_record_result && ptr6_record_result
    rescue => e
      Foreman::Logging.exception "Failed to rebuild DNS record for #{name}", e, :level => :error
      false
    end
  end

  def dns_a_record
    return unless dns? || @dns_a_record
    return unless ip_available?
    @dns_a_record ||= Net::DNS::ARecord.new dns_a_record_attrs
  end

  def dns_aaaa_record
    return unless dns6? || @dns_aaaa_record
    return unless ip6_available?
    @dns_aaaa_record ||= Net::DNS::AAAARecord.new dns_aaaa_record_attrs
  end

  def dns_ptr_record
    return unless reverse_dns? || @dns_ptr_record
    @dns_ptr_record ||= Net::DNS::PTR4Record.new reverse_dns_record_attrs
  end

  def dns_ptr6_record
    return unless reverse_dns6? || @dns_ptr6_record
    @dns_ptr6_record ||= Net::DNS::PTR6Record.new reverse_dns6_record_attrs
  end

  RECORD_TYPES.each do |record_type|
    define_method("del_dns_#{record_type}_record_safe") do # def del_dns_a_record_safe
      if send(:"dns_#{record_type}_record") # dns_a_record
        begin
          send(:"del_dns_#{record_type}_record") # del_dns_a_record
        rescue => e
          Foreman::Logging.exception "Proxy failed to delete DNS #{record_type}_record for #{name}, #{ip}, #{ip6}", e, :level => :error
        end
      end
    end
  end

  protected

  RECORD_TYPES.each do |record_type|
    record = :"dns_#{record_type}_record"

    define_method("recreate_#{record_type}_record") do # def recreate_a_record
      # set_dns_a_record unless dns_a_record.nil? || dns_a_record.valid?
      send(:"set_dns_#{record_type}_record") unless send(record).nil? || send(record).valid?
    end

    define_method("set_dns_#{record_type}_record") do # def set_dns_a_record
      send(record).create # dns_a_record.create
    end

    define_method("set_conflicting_dns_#{record_type}_record") do # def set_conflicting_dns_a_record
      send(record).conflicts.each { |c| c.create } # dns_a_record.conflicts.each { |c| c.create }
    end

    define_method("del_dns_#{record_type}_record") do # def del_dns_a_record
      send(record).destroy # dns_a_record.destroy
    end

    define_method("del_conflicting_dns_#{record_type}_record") do # def del_conflicting_dns_a_record
      send(record).conflicts.each { |c| c.destroy } # dns_a_record.conflicts.each { |c| c.destroy }
    end
  end

  private

  def dns_a_record_attrs
    { :hostname => hostname, :ip => ip, :resolver => domain.resolver, :proxy => domain.proxy }
  end

  def dns_aaaa_record_attrs
    { :hostname => hostname, :ip => ip6, :resolver => domain.resolver, :proxy => domain.proxy }
  end

  def reverse_dns_record_attrs
    { :hostname => hostname, :ip => ip, :proxy => subnet.dns_proxy }
  end

  def reverse_dns6_record_attrs
    { :hostname => hostname, :ip => ip6, :proxy => subnet6.dns_proxy }
  end

  def queue_dns
    return unless (dns? || dns6? || reverse_dns? || reverse_dns6?) && errors.empty?
    queue_remove_dns_conflicts if overwrite?
    new_record? ? queue_dns_create : queue_dns_update
  end

  def queue_dns_create
    logger.debug "Scheduling new DNS entries"
    queue.create(:name   => _("Create IPv4 DNS record for %s") % self, :priority => 10,
                 :action => [self, :set_dns_a_record]) if dns?
    queue.create(:name   => _("Create Reverse IPv4 DNS record for %s") % self, :priority => 10,
                 :action => [self, :set_dns_ptr_record]) if reverse_dns?
    queue.create(:name   => _("Create IPv6 DNS record for %s") % self, :priority => 10,
                 :action => [self, :set_dns_aaaa_record]) if dns6?
    queue.create(:name   => _("Create Reverse IPv6 DNS record for %s") % self, :priority => 10,
                 :action => [self, :set_dns_ptr6_record]) if reverse_dns6?
  end

  def queue_dns_update
    if old.ip != ip or old.hostname != hostname
      queue.create(:name   => _("Remove IPv4 DNS record for %s") % old, :priority => 9,
                   :action => [old, :del_dns_a_record]) if old.dns?
      queue.create(:name   => _("Remove Reverse IPv4 DNS record for %s") % old, :priority => 9,
                   :action => [old, :del_dns_ptr_record]) if old.reverse_dns?
      queue.create(:name   => _("Remove IPv6 DNS record for %s") % old, :priority => 9,
                   :action => [old, :del_dns_aaaa_record]) if old.dns6?
      queue.create(:name   => _("Remove Reverse IPv6 DNS record for %s") % old, :priority => 9,
                   :action => [old, :del_dns_ptr6_record]) if old.reverse_dns6?
      queue_dns_create
    end
  end

  def queue_dns_destroy
    return unless errors.empty?
    queue.create(:name   => _("Remove IPv4 DNS record for %s") % self, :priority => 1,
                 :action => [self, :del_dns_a_record]) if dns?
    queue.create(:name   => _("Remove Reverse IPv4 DNS record for %s") % self, :priority => 1,
                 :action => [self, :del_dns_ptr_record]) if reverse_dns?
    queue.create(:name   => _("Remove IPv6 DNS record for %s") % self, :priority => 1,
                 :action => [self, :del_dns_aaaa_record]) if dns6?
    queue.create(:name   => _("Remove Reverse IPv6 DNS record for %s") % self, :priority => 1,
                 :action => [self, :del_dns_ptr6_record]) if reverse_dns6?
  end

  def queue_remove_dns_conflicts
    return unless errors.empty?
    return unless overwrite?
    logger.debug "Scheduling DNS conflict removal"
    queue.create(:name   => _("Remove conflicting IPv4 DNS record for %s") % self, :priority => 0,
                 :action => [self, :del_conflicting_dns_a_record]) if dns? and dns_a_record and dns_a_record.conflicting?
    queue.create(:name   => _("Remove conflicting Reverse IPv4 DNS record for %s") % self, :priority => 0,
                 :action => [self, :del_conflicting_dns_ptr_record]) if reverse_dns? and dns_ptr_record and dns_ptr_record.conflicting?
    queue.create(:name   => _("Remove conflicting IPv6 DNS record for %s") % self, :priority => 0,
                 :action => [self, :del_conflicting_dns_aaaa_record]) if dns6? and dns_aaaa_record and dns_aaaa_record.conflicting?
    queue.create(:name   => _("Remove conflicting Reverse IPv6 DNS record for %s") % self, :priority => 0,
                 :action => [self, :del_conflicting_dns_ptr6_record]) if reverse_dns6? and dns_ptr6_record and dns_ptr6_record.conflicting?
  end

  def dns_conflict_detected?
    return false if ip.blank? or hostname.blank?
    # can't validate anything if dont have an ip-address yet
    return false unless require_ip4_validation? || require_ip6_validation?
    # we should only alert on conflicts if overwrite mode is off
    return false if overwrite?

    status = true
    status = failure(_("DNS A Records %s already exists") % dns_a_record.conflicts.to_sentence, nil, :conflict) if dns? and dns_a_record and dns_a_record.conflicting?
    status = failure(_("DNS AAAA Records %s already exists") % dns_aaaa_record.conflicts.to_sentence, nil, :conflict) if dns6? and dns_aaaa_record and dns_aaaa_record.conflicting?
    status = failure(_("DNS IPv4 PTR Records %s already exists") % dns_ptr_record.conflicts.to_sentence, nil, :conflict) if reverse_dns? and dns_ptr_record and dns_ptr_record.conflicting?
    status = failure(_("DNS IPv6 PTR Records %s already exists") % dns_ptr6_record.conflicts.to_sentence, nil, :conflict) if reverse_dns6? and dns_ptr6_record and dns_ptr6_record.conflicting?
    !status #failure method returns 'false'
  rescue Net::Error => e
    if domain.nameservers.empty?
      failure(_("Error connecting to system DNS server(s) - check /etc/resolv.conf"), e)
    else
      failure(_("Error connecting to '%{domain}' domain DNS servers: %{servers} - check query_local_nameservers and dns_conflict_timeout settings") % {:domain => domain.try(:name), :servers => domain.nameservers.join(',')}, e)
    end
  end
end
