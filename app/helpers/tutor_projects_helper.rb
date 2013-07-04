module TutorProjectsHelper
  def user_task_map(tasks)
    user_tasks      = {}

    tasks.each do |task|
      user_for_task = task.project.student.user

      user_tasks[user_for_task] ||= []
      user_tasks[user_for_task] << task
    end

    user_tasks
  end

  def gather_tasks(projects, task_selector)
    projects.map{|project| project.tasks }.flatten.select(&task_selector)
  end

  def unmarked_tasks(projects)
    gather_tasks projects, lambda {|task| task.awaiting_signoff? }
  end

  def needing_help_tasks(projects)
    gather_tasks projects, lambda {|task| task.need_help? && !task.awaiting_signoff }
  end

  def working_on_it_tasks(projects)
    gather_tasks projects, lambda {|task| task.working_on_it? && !task.awaiting_signoff }
  end

  def task_bar_item_class_for_mode(task, progress, mode)
    if mode == :action
      if task.complete?
        "action-complete"
      elsif task.awaiting_signoff?
        "action-awaiting-signoff"
      elsif task.fix_and_resubmit?
        "action-fix-and-resubmit"
      elsif task.fix_and_include?
        "action-fix-and-include"
      elsif task.redo?
        "action-redo"
      elsif task.need_help?
        "action-need-help"
      elsif task.working_on_it?
        "action-working-on-it"
      else
        "action-incomplete"
      end
    else
      if task.complete?
        progress_suffix = progress.to_s.gsub("_", "-")
        "progress-#{progress_suffix}"
      elsif task.awaiting_signoff?
        "action-awaiting-signoff"
      else
        "action-incomplete"
      end
    end
  end

  def task_bar_item(project, task, link, progress, mode, relative_number)
    progress_class  = task_bar_item_class_for_mode(task, progress, :progress)
    action_class    = task_bar_item_class_for_mode(task, progress, :action)

    description_text = (task.task_definition.description.nil? or task.task_definition.description == "NULL") ? "(No description provided)" : task.task_definition.description

    active_class = mode == :progress ? progress_class : action_class
    status_control_partial = render(partial: 'units/assessor_task_status_control', locals: { task:  task })

    link_to(
      task.task_definition.abbreviation || relative_number,
      link,
      class:  "task-progress-item task-#{task.id}-bar-item #{active_class}",
      title: task.task_definition.name,
      "data-progress-class" => progress_class,
      "data-action-class"   => action_class,
      "data-content"        => [
        description_text,
        h(status_control_partial)
      ].join("\n")
    )
  end

  def tasks_progress_bar(project, student, mode=:action)
    tasks = project.assigned_tasks

    progress = project.progress

    raw(tasks.each_with_index.map{|task, i|
      task_bar_item(project, task, '#', progress, mode, i + 1)
    }.join("\n"))
  end
end
