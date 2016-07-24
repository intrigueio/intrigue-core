###
### Scan factory: Standardize the creation and validation of scans
###
module Intrigue
class ScanFactory

  def self.register(klass)
    @scans = [] unless @scans
    @scans << klass
  end

  def self.list
    available_scans
  end

  def self.allowed_scans_for_entity_type(entity_type)
    available_scans.select {|scan_class| scan = scan_class.new; scan_class if scan.metadata[:allowed_types].include? entity_type}
  end

=begin
  #
  # XXX - can :name be set on the class vs the object
  # to prevent the need to call "new" ?
  #
  def self.include?(name)
    available_scans.each do |t|
      scan_object = s.new
      if (scan_object.metadata[:name] == name)
        return true # Create a new object and send it back
      end
    end
  false
  end

  #
  # XXX - can :name be set on the class vs the object
  # to prevent the need to call "new" ?
  #
  def self.create_by_name(name)
    available_scans.each do |s|
      scan_object = s.new
      if (scan_object.metadata[:name] == name)
        return scan_object # Create a new object and send it back
      end
    end

    ### XXX - exception handling? Should this return nil?
    raise "No scan by that name!"
  end

  #
  # XXX - can :name be set on the class vs the object
  # to prevent the need to call "new" ?
  #
  def self.create_by_pretty_name(pretty_name)
    available_scans.each do |s|
      scan_object = s.new
      if (scan_object.metadata[:pretty_name] == pretty_name)
        return scan_object # Create a new object and send it back
      end
    end

    ### XXX - exception handling? Should this return nil?
    raise "No scan by that name!"
  end
=end
  private

  def self.available_scans
    @scans
  end

end
end
