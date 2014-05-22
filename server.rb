require 'sinatra'
require 'csv'
require 'pry'
require 'shotgun'

def get_csv_to_hash(file_path)
  movies = Hash.new(0)

  CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
  movies[row[:id]] = {title: row[:title],
                      year: row[:year],
                      synopsis: row[:synopsis],
                      rating: row[:rating],
                      genre: row[:genre],
                      studio: row[:studio]
                    }
  end

  movies
end

def get_list_of_titles(movies_data)
  titles = []
  movies.data each do |movie|
    titles << movie[:title]
  end
  titles
end


def sort_hash_of_movies(file_path)
  movies_array = get_csv_to_hash(file_path).sort_by { |key, value| value[:title] }

  movies_hash = Hash.new(0)

  movies_array.each do |movie|
    movies_hash[movie[0]] = movie[1]
  end

  movies_hash
end

def import_array_of_sorted_movies(file_path)
    get_csv_to_hash(file_path).sort_by { |key, value| value[:title] }
end

def movies20_on_this_page(page,movies_hash)
  # the .to_i method will turn a params[:page] == nil to 0
  return movies_hash if page == 0

  drop_before = (page-1)*20
  movies_hash.drop(drop_before).take(20)
end

def page_numbers_to_display(page,movies_hash)
  return [1] if movies_hash == []
  array_of_pages = [page]
  length_of_movies_list = movies_hash.length
  total_pages = length_of_movies_list/20 + 1
  i = 1

  while i < 10
    array_of_pages << (page + i) if (page + i) <= total_pages
    array_of_pages.unshift(page - i) if (page - i) > 0
    i += 1
  end
  array_of_pages
end

def search_movies_for_query(query, movies_hash)
  movies_id = []

  movies_hash.each do |id, info|
    movies_id << [id, info ] if info[:title].downcase.include?(query.downcase) || (info[:synopsis] != nil && info[:synopsis].downcase.include?(query.downcase))
  end
  movies_id
end


get '/movies' do
  if !params[:query]
    @page = params[:page].to_i
    @hash_of_movie_info_sorted_by_titles = sort_hash_of_movies('movies.csv')
    @movies_on_this_page = movies20_on_this_page(@page, @hash_of_movie_info_sorted_by_titles)
    @title = "List of Movies"
    @pages = page_numbers_to_display(@page, @hash_of_movie_info_sorted_by_titles)

  else
    @query = params[:query]
    @page = 1
    @hash_of_movie_info_sorted_by_titles = sort_hash_of_movies('movies.csv')
    all_movies_found = search_movies_for_query(@query, @hash_of_movie_info_sorted_by_titles)
    @movies_on_this_page = movies20_on_this_page(@page, all_movies_found)
    @pages = page_numbers_to_display(@page, all_movies_found)
    @title = "Search results for: '#{params[:query]}'"
  end

  erb :home
end

get '/movies/:id' do
  movie_id = params[:id]
  list_of_movies = sort_hash_of_movies('movies.csv')
  @movie_info_hash = list_of_movies[movie_id]
  @title = @movie_info_hash[:title]
  erb :"movies/show", layout: :"movies/layout"
end



get '/' do
  redirect '/movies'
end

get '/:something' do
  redirect '/movies'
end


