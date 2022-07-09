require "mongo"

client = Mongo::Client.new([ '127.0.0.1:27017' ],
                           :database => 'mining_net_development')
                           
db = client.database                         
tasks = db[:queued_tasks]  ### getting "Queued Task" Collection, where will be my, still not completed, tasks.
 
un_tasks = tasks.find({}).sort(updated_at:-1) ### getting all task's documents sorted by last updated time.
for t in un_tasks do

  ## Criar arquivo pronto para logar e executar
  content = ['$log = ""', 'def run', 'begin', '$log = "==============Iniciando execução=================\n\n"']
  content = content + t[:content]
  content.push('return true', 'rescue StandardError => e',
               '$log += e.full_message', 'return false', 'end', 'end')
  file = File.new(t[:file_name], "w")
  file.write(content.join)
  file.close
  require_relative t[:file_name]

  if run
      ##delete from this collection, and insert on tasks_log
      client[:tasks_log].insert_one(tasks.find(:_id => t[:_id]).find_one_and_delete)
      client[:tasks_log].update_one({:_id => t[:_id]},
                                    { "$set" => { :log => $log} })
  else
    ### increment count_erros,
    tasks.update_one({:_id => t[:_id]},
                     { "$set" => { :log => $log} },
                     { "$inc" => { :count_erro => 1} } )
  end
end

