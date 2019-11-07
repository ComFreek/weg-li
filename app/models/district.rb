class District < ActiveRecord::Base

  geocoded_by :geocode_address
  after_validation :geocode

  acts_as_api

  api_accessible :public_beta do |template|
    %i(name zip email prefix latitude longitude created_at updated_at).each { |key| template.add(key) }
  end

  validates :name, :zip, :email, presence: :true

  has_many :notices

  def self.from_zip(zip)
    find_by(zip: zip)
  end

  def map_data
    {
      zoom: 13,
      latitude: latitude,
      longitude: longitude,
    }
  end

  def statistics(date = 100.years.ago)
    {
      notices: notices.since(date).count,
      users: User.where(id: notices.since(date).pluck(:user_id)).count,
    }
  end

  def geocode_address
    "#{zip}, #{name}, Deutschland"
  end

  def all_emails
    aliases.present? ? [email] + aliases : [email]
  end

  def display_name
    "#{email} (#{zip} #{name})"
  end

  def District.attach_prefix
    District.where(prefix: nil).limit(5000).each do |district|
      prefix = Vehicle.zip_to_prefix[district.zip]
      if prefix.present?
        district.update_attribute(:prefix, prefix)
      else
        Rails.logger.info("no match for #{district.name} #{district.zip}")
      end
    end
  end

  def District.attach_aliases
    {
      '80331' => ['npp-mue.muenchen.pi11@polizei.bayern.de'],
      '80333' => ['npp-mue.muenchen.pi12@polizei.bayern.de'],
      '80335' => ['npp-mue.muenchen.pi16@polizei.bayern.de'],
      '80336' => ['npp-mue.muenchen.pi14@polizei.bayern.de'],
      '80637' => ['npp-mue.muenchen.pi42@polizei.bayern.de'],
      '80687' => ['npp-mue.muenchen.pi41@polizei.bayern.de'],
      '80805' => ['npp-mue.muenchen.pi13@polizei.bayern.de'],
      '80809' => ['npp-mue.muenchen.pi43@polizei.bayern.de'],
      '80937' => ['npp-mue.muenchen.pi47@polizei.bayern.de'],
      '80997' => ['npp-mue.muenchen.pi44@polizei.bayern.de'],
      '81241' => ['npp-mue.muenchen.pi45@polizei.bayern.de'],
      '81373' => ['npp-mue.muenchen.pi15@polizei.bayern.de'],
      '81477' => ['npp-mue.muenchen.pi29@polizei.bayern.de'],
      '81541' => ['npp-mue.muenchen.pi21@polizei.bayern.de'],
      '81549' => ['npp-mue.muenchen.pi23@polizei.bayern.de'],
      '81675' => ['npp-mue.muenchen.pi22@polizei.bayern.de'],
      '81737' => ['npp-mue.muenchen.pi24@polizei.bayern.de'],
      '81829' => ['npp-mue.muenchen.pi25@polizei.bayern.de'],
    }.each do |zip, aliases|
      Rails.logger.info("updating #{zip} with #{aliases}")
      District.from_zip(zip).update!(aliases: aliases)
    end
  end
end
