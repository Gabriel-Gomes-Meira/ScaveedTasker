require "mongo"
require 'byebug'
client = Mongo::Client.new([ '127.0.0.1:27017' ],
                           :database => 'mining_net_development')
                           
db = client.database                         
tasks = db[:queued_tasks]  ### getting "Queued Task" Collection, where will be my, still not completed, tasks.
 
un_tasks = tasks.find({}).sort(updated_at:-1) ### getting all task's documents sorted by last updated time.
for t in un_tasks do
  byebug
  if File.exist?("scripts/#{t[:file_name]}") && system("ruby scripts/#{t[:file_name]}")
      ##delete from this collection, and insert on tasks_log
      client[:tasks_log].insert_one(tasks.find(:_id => t[:_id]).find_one_and_delete)


  else
    ### increment count_erros,
    tasks.update_one({:_id => t[:_id]},
                     { "$inc" => { :count_erro => 1} } )
  end
end

