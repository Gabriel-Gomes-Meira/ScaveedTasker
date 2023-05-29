
def output_log(connection, task, log)
    $log += log    
    connection[:queued_tasks].where(id: task[:id]).update(updated_at: Time.new, log: $log)
end

def prepare_enviroment(task)
    Dir::chdir(Dir::getwd)

    output_log "==============Preparando ambiente=================\n\n"    
    for line in task[:preset_content].split("\n") do
        output_log `#{line}`
    end
    output_log "==============Ambiente preparado=================\n\n"
end

