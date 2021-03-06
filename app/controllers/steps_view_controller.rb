class StepsViewController < UITableViewController
  include Refreshable
  
  attr_accessor :health_check
  attr_accessor :steps
  
  def initWithHealthCheck(health_check)
    @health_check = health_check
    @steps = []
    init
  end
  
  def viewDidLoad
    self.title = I18n.t("steps_controller.title")
    
    load_data
    
    if User.current.can_edit_health_checks?
      @plus_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemAdd, target:self, action:'add')
      @edit_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemEdit, target:self, action:'edit')
      @done_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemDone, target:self, action:'done_editing')
    
      self.navigationItem.setRightBarButtonItems [@plus_button, @edit_button]
    end
    
    on_refresh do
      health_check.reset_steps
      load_data
    end

    super
  end
  
  def viewWillAppear(animated)
    super
    tableView.reloadData
  end
  
  def viewWillDisappear(animated)
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning
  end
  
  def tableView(tableView, numberOfRowsInSection:section)
    @steps.size
  end
  
  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    fresh_cell.tap do |cell|
      step = steps[indexPath.row]
      cell.textLabel.text = step.class.summary
      cell.detailTextLabel.text = step.detail
    end
  end
  
  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    navigationController.pushViewController(StepViewController.alloc.initWithStep(steps[indexPath.row], parent:self), animated:true)
  end
  
  def tableView(tableView, canMoveRowAtIndexPath:indexPath)
    true
  end
  
  def tableView(tableView, moveRowAtIndexPath:source, toIndexPath:dest)
    step = steps.delete_at(source.row)
    steps.insert(dest.row, step)
    
    TinyMon.when_reachable do
      SVProgressHUD.showWithMaskType(SVProgressHUDMaskTypeClear)
      Step.sort(@steps) do |response, json|
        SVProgressHUD.dismiss
        TinyMon.offline_alert unless response.ok?
      end
    end
  end
  
  def tableView(tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:indexPath)
    if editingStyle == UITableViewCellEditingStyleDelete
      @step_to_delete = steps[indexPath.row]
      @action_sheet = UIActionSheet.alloc.initWithTitle(I18n.t("alert.really_delete"),
                                                               delegate:self,
                                                      cancelButtonTitle:I18n.t("alert.no_answer"),
                                                 destructiveButtonTitle:I18n.t("alert.yes_answer"),
                                                      otherButtonTitles:nil)

      @action_sheet.showInView(UIApplication.sharedApplication.keyWindow)
    end
  end
  
  def actionSheet(sender, clickedButtonAtIndex:index)
    if index == sender.destructiveButtonIndex
      TinyMon.when_reachable do
        SVProgressHUD.showWithMaskType(SVProgressHUDMaskTypeClear)
        @step_to_delete.destroy do |result, response|
          SVProgressHUD.dismiss
          if response.ok?
            @steps.delete(@step_to_delete)
            tableView.reloadData
          else
            TinyMon.offline_alert
          end
        end
      end
    else
      self.tableView.reloadData
      self.setEditing(true, animated:true)
      self.tableView.setEditing(true, animated:true)
    end
  end
  
  def load_data
    TinyMon.when_reachable do
      SVProgressHUD.showWithMaskType(SVProgressHUDMaskTypeClear)
      health_check.steps do |results, response|
        SVProgressHUD.dismiss
        if response.ok? && results
          @steps = results
        else
          TinyMon.offline_alert
        end
        tableView.reloadData
        end_refreshing
      end
    end
  end
  
  def add
    navigationController.pushViewController(SelectStepViewController.alloc.initWithHealthCheck(@health_check, parent:self), animated:true)
  end
  
  def edit
    tableView.setEditing true, animated:true
    self.viewDeckController.panningMode = IIViewDeckNoPanning
    self.navigationItem.setRightBarButtonItems [@plus_button, @done_button]
  end
  
  def done_editing
    tableView.setEditing false, animated:true
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning
    self.navigationItem.setRightBarButtonItems [@plus_button, @edit_button]
  end

private
  def fresh_cell
    tableView.dequeueReusableCellWithIdentifier('Cell') ||
    UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:'Cell').tap do |cell|
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator
    end
  end
end
