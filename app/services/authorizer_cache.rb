module AuthorizerCache
  def invalidate_cache
    Rails.cache.write("authorizer-#{user}", {})
  end

  def cached_subject(subject)
    cached_authorizer = Rails.cache.fetch("authorizer-#{user}")
    return {} unless cached_authorizer.present?
    cached_authorizer[subject]
  end

  def write_cache_subject(subject, collection)
    cached_authorizer = Rails.cache.fetch("authorizer-#{user}")
    if cached_authorizer.nil?
      raise ::Foreman::Exception.new(
        N_('Tried to write to a cache that has not been initialized yet'))
    end
    cached_authorizer[subject] = collection
    Rails.cache.write("authorizer-#{user}", cached_authorizer)
  end

  def update_cache(subject, permission)
    return if cached_subject(subject.to_s)[permission].present?
    authorized_subjects = find_collection(subject, :permission => permission)
    new_cache_subject = cached_subject(subject.to_s).
      merge(permission => authorized_subjects)

    write_cache_subject(subject.to_s, new_cache_subject)
  end
end

