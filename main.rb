require "pg"
require "sequel"

servicewd = Dir::getwd  ##getting working directory to grant that anyone script will be executed on main work directory's service.
db = Sequel.connect('postgres://postgres:password@db/scaveed_development')


tasks = db[:queued_tasks]  ### getting "Queued Task" Table, where will be my, still not completed, tasks.

### getting the first task (by updated_at)
while tasks.order(:updated_at).first
  # sleep 60
    t = tasks.order(:updated_at).first
    ## Criar arquivo pronto para logar e executar, no diretório de execução
    content = ['$log = ""', 'def run', '$log = "==============Iniciando execução=================\n\n"']
    content += t[:content].split("\n")
    content.push('$log += "==============Terminando execução=================\n\n"',
                 'return true', 'rescue StandardError => e', '$log += e.full_message',
                 'return false', 'end')
    Dir::chdir(servicewd)
    file = File.new(t[:file_name], "w")
    file.write(content.join("\n"))
    file.close
    path_creation = "#{servicewd}/#{t[:file_name]}"

    begin
      require_relative t[:file_name]
      tasks.where(id: t[:id]).update(state: 1, initialized_at: Time.new)

      if run
        ##delete from this table, and insert on tasks_log
        t[:terminated_at] = Time.new
        t[:log]  = $log
        db[:log_tasks].insert(t.except(:id))
        tasks.where(id: t[:id]).delete
      else
        ### increment count_erros
        tasks.where(id: t[:id]).update(log: $log, state: 0, updated_at: Time.new,
                                       count_erro: t[:count_erro]+1)
      end

    rescue StandardError => e
      tasks.where(id: t[:id]).update(log: e.full_message, state: 0, updated_at: Time.new,
                                     count_erro: t[:count_erro]+1)

    rescue SyntaxError => e
      tasks.where(id: t[:id]).update(log: e.full_message, state: 0, updated_at: Time.new,
                                     count_erro: t[:count_erro]+1)

    rescue LoadError => e
      tasks.where(id: t[:id]).update(log: e.full_message, state: 0, updated_at: Time.new,
                                     count_erro: t[:count_erro]+1)


    end

    ## remover arquivo após uso.
    `rm #{path_creation}`
end
