post '/search' do
	search_name = params[:search]
	results = create_result_array(read_csv_from_s3)
	plays = 0
	wins = 0
	results.each do |result| 
		if result[0] == search_name || result[1] == search_name
			plays += 1
		end
		if result[2] == search_name
			wins += 1
		end
	end
	"plays = #{plays} and wins = #{wins}"
