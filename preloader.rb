

def prepare_enviroment(task)
    Dir::chdir(Dir::getwd)

    $log = "==============Preparando ambiente=================\n\n"    
    for line in task[:preset_content].split("\n") do
        $log += `#{line}`
    end
    $log += "==============Ambiente preparado=================\n\n"
end

