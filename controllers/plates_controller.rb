class InjuriesController < ApplicationController
    #before_action :authenticate_user!
    
    helper_method :sort_column, :sort_direction
    
    def index
        require_login
        
        if (params.has_key?(:date) && params[:category] == "date") #EDIT HERE, CHECK IF DATE IS ATTACHED
            @injuries = Injury.searchdate(params[:date])
        elsif (params.has_key?(:search))
            @injuries = Injury.search(params[:search], params[:category])
        else
           @injuries = Injury.all
        end
        puts "#{sort_column}";
         @injuries = @injuries.order(Arel.sql("lower(text(#{sort_column})) #{sort_direction}"));
         #@injuries = @injuries.order(Arel.sql("lower(#{sort_column}) #{sort_direction}"));  #locally!!!!!!!!!!!!!!!! 
      
      
      
        respond_to do |format|
            format.html
            format.csv { send_data Injury.to_csv }
            format.xls { send_data Injury.to_csv(col_sep: "\t") }
        end
    end
    
    def show
        require_login
        @injury = Injury.find(params[:id]);
    end
    
    def new
        require_login
        @injury = Injury.new
    end
    
    def create
        require_login
        #render plain: params[:post].inspect #render is gonna print the object
        @injury = Injury.new(injury_params);
        
        if(@injury.save)
            redirect_to @injury
        else
            render 'new'
        end
    end
    
    def edit
        require_login
        @injury = Injury.find(params[:id]);
    end
    
    def update
        require_login
        @injury = Injury.find(params[:id]);
        
        if(@injury.update(injury_params))
            redirect_to @injury
        else
            render 'edit'
        end
    end
    
    def destroy
        require_login
        @injury = Injury.find(params[:id]);
        @injury.destroy
        
        redirect_to injuries_path
    end
    
    def generate
        require_login
        if(params.has_key?(:id)) 
            @injury = Injury.find(params[:id]);
            base_name = @injury.name.delete(' ')+"_Injury_Report";
            pdf_filename = File.join(Rails.root, "generated_pdfs/" + base_name)
            generate_pdf(pdf_filename)
            send_file(pdf_filename, :filename => base_name + ".pdf", :type => "application/pdf")
        else
            redirect_to injuries_path
        end
    end
    
    
    

=begin
    def search
        @injuries = Injury.where(nil)
        filtering_params(params).each do |key, value|
            @injuries = @injuries.public_send(key, value) if value.present?
        end
    end

    private

    # A list of the param names that can be used for filtering the Product list
    def filtering_params(params)
        params.slice(:name, :date, :sport)
    end
=end
   
    
    private def injury_params
    params.require(:injury).permit(:sport, :name, :exposure, :date, :reportnotes, :part, :injurytype, :symptoms, :injurynotes, :immediatetreatment, :returndate, :returned, :treatmentnotes, :attachment);
    end
    # deleted :side
    
    
    private
    def sortable_columns
    ["date", "id", "sport", "name", "part", "injurytype", "returned", "attachment"]
    end

    def sort_column
        sortable_columns.include?(params[:column]) ? params[:column] : "id"
    end

    def sort_direction
        %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
    
    def require_login
        unless current_user
            redirect_to login_url
        end
    end
    
    def generate_pdf(pdf_filename)
        Prawn::Document.generate(pdf_filename) do |pdf|
            pdf.text @injury.name, :align => :center, :size => 30, :style => :bold
            pdf.move_up 3
            pdf.text "Injury Report", :align => :center, :size => 15, :style => :italic
            pdf.move_up 15
            pdf.text "Created at: " + @injury.created_at.strftime("%b %d %Y"), :align => :left, :size => 10, :style => :italic
            #pdf.text "Created at: " + @injury.created_at.to_s, :align  => :left, :style => :italics, :size =>10
            pdf.move_down 8
            pdf.line [0, 665], [540, 665]
            pdf.stroke
            pdf.move_down 20

            rows1 = []
            rows2 = []
            rows3 = []
            rowindex = 1
            changeindexflag = false
            @injury.attributes.each_pair do |name, value|
                if name != "updated_at" && name != "attachment"  && name != "created_at"  
                    #make name
                    if name == "id"
                        finalname = "ID"
                        rowindex = 1
                    elsif name == "id"
                        finalname = "ID"
                    elsif name == "reportnotes"
                        finalname = "Notes"
                        changeindexflag = true
                    elsif name == "injurytype"
                        finalname = "Injury Type"
                    elsif name == "injurynotes"
                        finalname = "Notes"
                        changeindexflag = true
                    elsif name == "immediatetreatment"
                        finalname = "Immediate Treatment"
                    elsif name == "returndate"
                        finalname = "Return Date"
                    elsif name == "treatmentnotes"
                        finalname = "Notes"
                    else
                        finalname = name
                    end
                    finalname = finalname.slice(0,1).capitalize + finalname.slice(1..-1)
                    
                    #make value
                    if value == "" || value == nil
                        finalvalue = "None"
                    elsif value == true || value == "true"
                        finalvalue = "Yes"
                    elsif value == false || value == "false"
                        finalvalue = "No"
                    elsif name == "side"
                        finalvalue = value.slice(0,1).capitalize + value.slice(1..-1)
                    elsif name == "date" || name == "returndate"
                        finalvalue = value.strftime("%B %d %Y")
                    else
                        finalvalue = value
                    end
                    
                    onerow = [finalname.to_s, finalvalue.to_s]
                    
                    #split table into 3 parts
                    if rowindex == 1
                        rows1.push(onerow)
                    elsif rowindex == 2
                        rows2.push(onerow)
                    elsif rowindex == 3
                        rows3.push(onerow)
                    end
                    
                    #this lets us change the row after a certain attribute is added, instead of before
                    if changeindexflag
                        rowindex += 1;
                        changeindexflag = false
                    end
                    
                end
            end
            
            #drawing tables
            pdf.text "Basic Information", :align => :center, :size => 18, :style => :bold, :color => "97befc"
            tables = [];
            tables[0] = pdf.table(rows1, :position => :center, :column_widths => [140, 400]) do
                
                column(0).style(:font_style => :bold)
                cells.style(:padding => 8, :border_color => "97befc")
            end
            pdf.move_down 30
            pdf.text "Injury Details", :align => :center, :size => 18, :style => :bold, :color => "97befc"
            
            tables[1] = pdf.table(rows2, :position => :center, :column_widths => [140, 400]) do 
                column(0).style(:font_style => :bold)
                cells.style(:padding => 8, :border_color => "97befc")
            end
            
            pdf.move_down 30
            pdf.text "Treatment Details", :align => :center, :size => 18, :style => :bold, :color => "97befc"
            tables[2] = pdf.table(rows3, :position => :center, :column_widths => [140, 400]) do
                column(0).style(:font_style => :bold)
                cells.style(:padding => 8, :border_color => "97befc")
            end
            tables[0].column(0).font_style = :bold
            #styling
            
            pdf.move_down 20
            
            #pdf.stroke_axis
            
            
            
        end
    end
end
