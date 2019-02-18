require 'csv'
class Injury < ApplicationRecord
    
    #mount_uploader :attachment, AttachmentUploader 
    has_one_attached :attachment
    
    
    validates :sport, presence: true
    validates :name, presence: true
    #validates :side, presence: true
    validates :part, presence: true
    validates :injurytype, presence: true
    validates :returned, presence: true
    validates :date, presence: true
    
    def self.search(search, category)
        if search
            where(category + " LIKE ?", "%#{search.downcase}%").all;
        else
            all
        end
    end
    
    def self.searchdate(inDate)
        Injury.connection;
        if inDate
            datestring = Date.new(inDate["year"].to_i, inDate["month"].to_i, inDate["day"].to_i).to_s
            where("date = '#{datestring}'")
        else
            all
        end
    end
    
        
    
def self.to_csv(options = {})
  CSV.generate(options) do |csv|
    csv << column_names
    all.each do |injury|
      csv << injury.attributes.values_at(*column_names)
    end
  end
  
  
end
end
