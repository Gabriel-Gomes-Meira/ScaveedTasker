require "mongo"

client = Mongo::Client.new([ '127.0.0.1:27017' ],
                           :database => 'mining_net_development')
                           
db = client.database                         
tasks = db[:queued_tasks]  ### getting "Queued Task" Collection, where will be my, still not completed, tasks.
 
### getting all task's documents sorted by last updated time.
while tasks.find({}).sort(updated_at:1).first
  t = tasks.find({}).sort(updated_at:1).first
  ## Criar arquivo pronto para logar e executar
  content = ['$log = ""', 'def run', '$log = "==============Iniciando execução=================\n\n"']
  content = content + t[:content]
  content.push('$log = "==============Terminando execução=================\n\n"',
               'return true', 'rescue StandardError => e', '$log += e.full_message',
               'return false', 'end')
  file = File.new(t[:file_name], "w")
  file.write(content.join("\n"))
  file.close

  begin
    require_relative t[:file_name]
    tasks.update_one({:_id => t[:_id]},
                    { "$set" => { :state => 1, :initialized_at => Time.new} })
    if run
        ##delete from this collection, and insert on tasks_log
        client[:tasks_log].insert_one(tasks.find(:_id => t[:_id]).find_one_and_delete)
        client[:tasks_log].update_one({:_id => t[:_id]},
                                      { "$set" => { :log => $log, :state => 2, :terminated_at => Time.new } })
    else
      ### increment count_erros,
      tasks.update_one({:_id => t[:_id]},
                      { "$set" => { :log => $log, :state => 0, :updated_at => Time.new},
                       "$inc" => { :count_erro => 1} } )
    end
    
  rescue StandardError => e
    tasks.update_one({:_id => t[:_id]},
                    { "$set" => { :log => e.full_message, :state => 0, :updated_at => Time.new},
                     "$inc" => { :count_erro => 1} } )
  rescue SyntaxError => e
    tasks.update_one({:_id => t[:_id]},
                    { "$set" => { :log => e.full_message, :state => 0, :updated_at => Time.new},
                      "$inc" => { :count_erro => 1} } )
  rescue LoadError => e
    tasks.update_one({:_id => t[:_id]},
                    { "$set" => { :log => e.full_message, :state => 0, :updated_at => Time.new},
                     "$inc" => { :count_erro => 1}}  )
  end

  File.delete(t[:file_name])
end
