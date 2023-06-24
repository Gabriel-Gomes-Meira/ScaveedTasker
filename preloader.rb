require 'open3'

def output_log(log)
    $log += log+"\n"    
    $db[:queued_tasks].where(id: $curr_id_task).update(updated_at: Time.new, log: $log)
end

def prepare_enviroment(task)
    Dir::chdir(Dir::getwd)

    output_log "==============Preparando ambiente=================\n\n"
    task[:preset_content].split("\n").each do |line|
        output_log "Executando comando: #{line}"
        stdout, stderr, status = Open3.capture3(line)  # Executar o comando usando Open3
        output_log stdout
        output_log stderr unless stderr.empty?
        output_log "Comando executado com status: #{status}"
    end
  output_log "==============Ambiente preparado=================\n\n"
end

