require 'sinatra'
require 'csv'
require_relative 'new_tic_tac.rb'
require_relative 'human.rb'
require_relative 'sequential_ai.rb'
require_relative 'random_ai.rb'
require_relative 'unbeatable_ai.rb'
require 'aws/s3' 
load './local_env.rb' if File.exists?("./local_env.rb")

def write_file_to_s3(player_1, player_2, winner, date_time)
	AWS::S3::Base.establish_connection!(
  :access_key_id => ENV['S3_KEY'],
  :secret_access_key => ENV['S3_SECRET']   
)
	file = 'summary.csv' 
	bucket = 'tictactoe-game5'
	csv = AWS::S3::S3Object.value(file, bucket)
	csv << player_1 + ", " + player_2 + ", " + winner + ", " + date_time.to_s + "\n"
	AWS::S3::S3Object.store(File.basename(file), 
        csv, 
        bucket, 
        :access => :public_read)	
end

# Added method 28
def read_csv_from_s3
	file = 'summary.csv'
	bucket = 'tictactoe-game5'
	object_from_s3 = AWS::S3::S3Object.value(file, bucket)
end

def create_result_array(content)
	file = content
	result = file.split("\n")
	array = Array.new
	result.each { |x| array.push(x.split(","))}
	array
end
def write_to_csv(player_1, player_2, winner, date_time) 
	CSV.open("summary.csv", "a") do |csv|
  		csv << ["#{player_1}" + ", " + "#{player_2}" + ", " + "#{winner}" + ", " + "#{date_time}"]
	end
end

def check_file_length()
	File.readlines("summary.csv").size
end
enable :sessions

get '/' do
	@title = "Welcome to Tic Tac Toe"
	session[:board] = Board.new
	erb :home, :locals => { :board => session[:board].board_positions }
end

post '/game' do
	session[:name_player_1] = params[:player_1]
	session[:p1] = Human.new("X")
	session[:current_player] = session[:p1]
	session[:current_player_name] = session[:name_player_1]

	erb :opponent, :locals => { :board => session[:board].board_positions }	
end

post '/opponent' do
	player_2 = params[:player_2]

	if player_2 == "human"
		session[:p2] = Human.new("O")

		erb :opponent_name, :locals => { :board => session[:board].board_positions }

	elsif player_2 == "sequential_ai"
		session[:p2] = SequentialAI.new("O")
		session[:name_player_2] = "CPU"

		redirect '/get_move'

	elsif player_2 == "random_ai"
		session[:p2] = RandomAI.new("O")
		session[:name_player_2] = "CPU"

		redirect '/get_move'

	# else player_2 == "unbeatable_ai"
	# 	session[:p2] = UnbeatableAI.new("O")

	# 	redirect '/get_move'
	end
end

post '/opponent_name' do
	session[:name_player_2] = params[:player_2]

	redirect '/get_move'
end

get '/get_move' do
	move = session[:current_player].get_move(session[:board].ttt_board)

	if move == "NO"
		erb :get_move, :locals => { :current_player => session[:current_player], :current_player_name => session[:current_player_name], :board => session[:board].board_positions }
	elsif session[:board].valid_space?(move)
		redirect '/make_move?move=' + move.to_s 
	else
		# Does line 101 ever happen?
		redirect '/get_move'
	end
end

post '/get_player_move' do
	move = params[:move_spot].to_i

	if session[:board].valid_space?(move)
		redirect '/make_move?move=' + move.to_s
	else
		redirect '/get_move'
	end
end

get '/make_move' do
	move_spot = params[:move].to_i

	session[:board].update_board((move_spot - 1), session[:current_player].marker)

	if session[:board].game_won?(session[:current_player].marker) == true
		player_1 = session[:name_player_1]
		player_2 = session[:name_player_2]
		winner = session[:current_player_name]
		date_time = DateTime.now

		# write_to_csv(player_1, player_2, winner, date_time)

		# Added line 134
		write_file_to_s3(player_1, player_2, winner, date_time)

		erb :win, :locals => { :current_player => session[:current_player], :current_player_name => session[:current_player_name], :board => session[:board].board_positions }
	elsif session[:board].game_ends_in_tie? == true
		player_1 = session[:name_player_1]
		player_2 = session[:name_player_2]
		winner = "Tie"
		date_time = DateTime.now

		# write_to_csv(player_1, player_2, winner, date_time)

		erb :tie, :locals => { :board => session[:board].board_positions }
	else
		if session[:current_player].marker == "X"
			session[:current_player] = session[:p2]
			session[:current_player_name] = session[:name_player_2]
		else
			session[:current_player] = session[:p1]
			session[:current_player_name] = session[:name_player_1]
		end

		redirect '/get_move'
	end	
end

get '/upload' do
  	winning_results = 'summary.csv'
  	write_file_to_s3(winning_results)
end

get '/update_csv' do
	names = create_result_array(read_csv_from_s3)
	names.shift
	
	erb :update_csv, :layout => :results_layout, :locals => { :names => names, :board => session[:board].board_positions }
end

get '/win' do 
end

get '/tie' do
end

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
	"plays = #{plays} and wins = #{wins} #{results}"
end


#result ["jen", "dawn", "dawn", "date"]