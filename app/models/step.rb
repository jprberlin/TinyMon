class Step < RemoteModule::RemoteModel
  attr_accessor :id, :type, :position, :health_check_id, :data
  
  collection_url "accounts/:account_id/sites/:site_permalink/health_checks/:check_permalink/steps"
  member_url "accounts/:account_id/sites/:site_permalink/health_checks/:check_permalink/steps/:id"
  
  attr_accessor :health_check
  
  def self.data_attribute(*fields)
    fields.each do |field|
      define_method field do
        data[field.to_s]
      end
      
      define_method "#{field}=" do |value|
        data[field.to_s] = value
      end
    end
  end
  
  def site_permalink
    health_check && health_check.site && health_check.site.permalink
  end
  
  def check_permalink
    health_check && health_check.permalink
  end
  
  def summary
    type
  end
  
  def detail
    ""
  end
end
