class Step < RemoteModule::RemoteModel
  attr_accessor :id, :type, :position, :health_check_id
  attribute :data
  
  collection_url "accounts/:account_id/sites/:site_permalink/health_checks/:check_permalink/steps"
  
  attr_accessor :health_check
  
  def self.data_attribute(*fields)
    fields.each do |field|
      define_method field do
        self.data ||= {}
        self.data[field.to_s]
      end
      
      define_method "#{field}=" do |value|
        self.data ||= {}
        self.data[field.to_s] = value
      end
    end
  end
  
  def self.sort(array, &block)
    self.post(array.first.sort_url, :payload => { :step => array.map { |s| s.id } }, &block)
  end
  
  def create(&block)
    self.class.post(collection_url, :payload => { self.class.name.underscore => attributes }, :query => { :type => self.name.sub("Step", "").underscore }) do |response, json|
      block.call json ? self.class.new(json) : nil
    end
  end
  
  def site_permalink
    health_check && health_check.site && health_check.site.permalink
  end
  
  def check_permalink
    health_check && health_check.permalink
  end
  
  def account_id
    health_check && health_check.account_id
  end
  
  def summary
    type
  end
  
  def detail
    ""
  end
end
