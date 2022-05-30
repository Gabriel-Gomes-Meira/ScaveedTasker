require "mongo"

client = Mongo::Client.new([ '127.0.0.1:27017' ],
                           :database => 'mining_net_development')
                           
db = client.database                         
tasks = db[:queued_tasks]  ### getting "Queued Task" Collection, where will be my, still not completed, tasks.
 
un_tasks = tasks.find({}).sort(updated_at:-1) ### getting all task's documents sorted by last updated time.
for t in un_tasks do
  
  if File.exist?("scripts/#{t[:file_name]}")
    output = `ruby scripts/#{t[:file_name]}` ##capture all output for log
    if eval(output.split("\n").last) ### the line from output
      ##delete from this collection, and insert on tasks_log
      client[:tasks_log].insert_one(tasks.find(:_id => t[:_id]).find_one_and_delete)    
      client[:tasks_log].update_one({:_id => t[:_id]},                       
                       { "$set" => { :log => output} })
    else
      ### increment count_erros,
      tasks.update_one({:_id => t[:_id]},
                       { "$inc" => { :count_erro => 1} },
                       { "$set" => { :log => output} })
    
    end  
  else
   tasks.update_one({:_id => t[:_id]},
                         { "$inc" => { :count_erro => 1} },
                         { "$set" => { :log => "Arquivo (scripts/#{t[:file_name]}) nao foi encontrado!"} }) 
  end
end
