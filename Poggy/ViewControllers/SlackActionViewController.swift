//
//  SlackActionViewController.swift
//  Poggy
//
//  Created by Francesco Pretelli on 9/05/16.
//  Copyright © 2016 Francesco Pretelli. All rights reserved.
//

import UIKit
import Eureka

class SlackActionViewController:FormViewController, PoggySlackDelegate, PoggyToolbarDelegate {
    
    private var actionToEdit:PoggyAction?
    private var currentSlackAction = PoggyAction()
    private let poggyToolbar = PoggyToolbar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        title = ""
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = NSLocalizedString("Slack Action", comment: "")
    }
    
    func setupTableView() {
        ButtonRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = PoggyConstants.POGGY_BLUE
            cell.backgroundColor = UIColor.blackColor()
        }
        
        PushRow<String>.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = PoggyConstants.POGGY_BLUE
            cell.backgroundColor = UIColor.blackColor()
            cell.detailTextLabel?.textColor = UIColor.whiteColor()
        }
        
        TextRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = PoggyConstants.POGGY_BLUE
            cell.backgroundColor = UIColor.blackColor()
            cell.textField.textColor = UIColor.whiteColor()
        }
        
        form
            +++ Section("") { section in
            }
            
            <<< TextRow("Description") { row in
                row.title = NSLocalizedString("Description", comment: "")
            }.cellUpdate({ (cell, row) in
                cell.textField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Enter Description", comment: ""), attributes: [NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                cell.textField.text = self.currentSlackAction.actionDescription
            })
            
            <<< PushRow<String>() { row in
                row.title = NSLocalizedString("Slack Team", comment: "")
                row.presentationMode = .SegueName(segueName: "TeamSelectionSegue", completionCallback: nil)
            }.cellUpdate({ (cell, row) in
                cell.detailTextLabel?.text = self.currentSlackAction.slackTeam
            })
            
            <<< PushRow<String>() { row in
                row.title = NSLocalizedString("Channel", comment: "")
                row.presentationMode = .SegueName(segueName: "ChannelSelectionSegue", completionCallback: nil)
            }.cellUpdate({ (cell, row) in
                cell.detailTextLabel?.text = self.currentSlackAction.slackChannel
                row.disabled = self.currentSlackAction.slackTeam == nil ? true : false
                print (row.isDisabled)
            })
            <<< TextRow("Message") { row in
                row.title = NSLocalizedString("Message", comment: "")
            }.cellUpdate({ (cell, row) in
                cell.textField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Message To Send", comment: ""), attributes: [NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                cell.textField.text = self.currentSlackAction.message
            }).cellSetup({ (cell, row) in
                self.poggyToolbar.poggyDelegate = self
                self.poggyToolbar.setButtonTitle(NSLocalizedString("ADD", comment: ""))
                cell.textField.inputAccessoryView = self.poggyToolbar
                self.poggyToolbar.sizeToFit()
            })
        
        super.tableView?.backgroundColor = UIColor.blackColor()
        super.tableView?.separatorColor = PoggyConstants.POGGY_BLUE
        super.tableView?.tintColor = PoggyConstants.POGGY_BLUE
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TeamSelectionSegue" {
            if let destination = segue.destinationViewController as? SlackTeamSelectionViewController {
               destination.delegate = self
            }
        } else if segue.identifier == "ChannelSelectionSegue" {
            if let destination = segue.destinationViewController as? SlackChannelSelectionViewController {
                destination.teamToken = currentSlackAction.slackToken
                destination.delegate = self
            }
        }
    }
    
    func updateFromActionsViewController(action:PoggyAction) {
        actionToEdit = action
    }
    
    func addNewAction() {
        let descRow = form.rowByTag("Description") as? TextRow
        currentSlackAction.actionDescription = descRow?.cell.textField.text
        
        let messageRow = form.rowByTag("Message") as? TextRow
        currentSlackAction.message = messageRow?.cell.textField.text
        
        if !actionIsReady() {
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Fields cannot be empty", comment: ""), preferredStyle: .Alert)
            let actionCancel = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: UIAlertActionStyle.Cancel) { (action) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(actionCancel)
            presentViewController(alert, animated: false, completion: nil)
            return
        }
        
        currentSlackAction.actionIndex = actionToEdit?.actionIndex
        let update = actionToEdit == nil ? false : true
        ActionsHelper.instance.addAction(currentSlackAction, update:update)
        NSNotificationCenter.defaultCenter().postNotificationName(PoggyConstants.NEW_ACTION_CREATED, object: nil)
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func actionIsReady() -> Bool {
        if currentSlackAction.slackChannel != nil && currentSlackAction.slackTeam != nil && currentSlackAction.message != nil && currentSlackAction.actionDescription != nil {
            return true
        }
        return false
    }
    
    //MARK: - delegate functions
    
    func slackTeamSelected(teamName: String, teamToken: String) {
        currentSlackAction.slackTeam = teamName
        currentSlackAction.slackToken = teamToken
    }
    
    func slackChannelSelected(channelName: String) {
        currentSlackAction.slackChannel = channelName
    }
    
    //Toolbar delegate
    
    func onPoggyToolbarButtonTouchUpInside() {
        addNewAction()
    }
}

//MARK: - Slack protocol

protocol PoggySlackDelegate {
    func slackTeamSelected(teamName: String, teamToken: String)
    func slackChannelSelected(channelName: String)
}

//MARK: - Team Selection Class

class SlackTeamSelectionViewController: FormViewController {
    
    var slackTeams:[String: String]?
    var delegate:PoggySlackDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Select Team", comment: "")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        form.removeAll()
        slackTeams = SlackHelper.instance.getAuthCredentials()
        setupTableView()
    }
    
    func setupTableView() {
        
        ButtonRow.defaultCellUpdate = { cell, row in
            cell.textLabel?.textColor = PoggyConstants.POGGY_BLUE
            cell.backgroundColor = UIColor.blackColor()
        }
        
        form +++ Section("") { section in
        
        }
        
        if let availableTeams = slackTeams {
            for team in availableTeams {
               form.last! <<< ButtonRow() { row in
                    row.title = team.0
                    row.onCellSelection({ (cell, row) in
                        print(team.1)
                        if self.delegate != nil {
                            self.delegate?.slackTeamSelected(team.0, teamToken: team.1)
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                    })
                }
            }
        }
        
        form +++ ButtonRow() { row in
                row.title = NSLocalizedString("Add Slack Team", comment: "")
                row.onCellSelection({ (cell, row) in
                    self.doOAuthSlack()
                }).cellUpdate({ (cell, row) in
                    cell.textLabel?.textColor = UIColor.blackColor()
                    cell.backgroundColor = PoggyConstants.POGGY_BLUE
                })
        }
        
        super.tableView?.backgroundColor = UIColor.blackColor()
        super.tableView?.separatorColor = PoggyConstants.POGGY_BLUE
        super.tableView?.tintColor = PoggyConstants.POGGY_BLUE
    }
    
    func doOAuthSlack(){
        SlackHelper.instance.authenticate(self) { (slackDetails) in
            if let slack = slackDetails {
                print (slack.teamName)
                print (slack.token)
            }
        }
    }
}

//MARK: - Channel Selection Class

class SlackChannelSelectionViewController: FormViewController {
    var teamToken:String?
    var delegate:PoggySlackDelegate?
    
    private var publicChannels:[SlackChannel]?
    private var privateChannels:[SlackChannel]?
    private var users:[SlackUser]?
    private let apiDispatchGroup = dispatch_group_create();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Select Channel", comment: "")
        getPublicChannels()
        getPrivateChannels()
        getUsers()
        
        dispatch_group_notify(apiDispatchGroup, dispatch_get_main_queue(), {
            self.setupTableView()
        })
    }
    
    func setupTableView() {
        
        let publicSection = NSLocalizedString("Public", comment: "")
        let privateSection = NSLocalizedString("Private", comment: "")
        let usersSection = NSLocalizedString("Users", comment: "")
        
        form
            +++ Section("") { section in
            
            }
            
        <<< SegmentedRow<String>("channels"){
                $0.options = [publicSection, privateSection, usersSection]
                $0.value = publicSection
        }.cellSetup({ (cell, row) in
            cell.backgroundColor = UIColor.blackColor()
            cell.tintColor = PoggyConstants.POGGY_BLUE
        })
        
        +++ Section() { section in
            section.tag = publicSection
            let hiddenCondition = "$channels != '\(publicSection)'"
            section.hidden = Condition(stringLiteral: hiddenCondition)
            
            if let pubChannels = publicChannels {
                for channel in pubChannels {
                    section.append(ButtonRow() { row in
                        row.title =  channel.name
                        row.onCellSelection({ (cell, row) in
                            if self.delegate != nil {
                                self.delegate?.slackChannelSelected(channel.name!)
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        })
                    })
                }
            }
        }
        
        form +++ Section() { section in
            section.tag = privateSection
            let hiddenCondition = "$channels != '\(privateSection)'"
            section.hidden = Condition(stringLiteral: hiddenCondition)
       
            if let privateChannels = privateChannels {
                for channel in privateChannels {
                    section.append( ButtonRow() { row in
                        row.title =  channel.name
                        row.onCellSelection({ (cell, row) in
                            if self.delegate != nil {
                                self.delegate?.slackChannelSelected(channel.name!)
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        })
                    })
                }
            }
        }
        
        form +++ Section() { section in
            section.tag = usersSection
            let hiddenCondition = "$channels != '\(usersSection)'"
            section.hidden = Condition(stringLiteral: hiddenCondition)
    
            if let users = users {
                for user in users {
                    section.append(ButtonRow() { row in
                        row.title =  user.username
                        row.onCellSelection({ (cell, row) in
                            if self.delegate != nil {
                                self.delegate?.slackChannelSelected(user.username!)
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        })
                    })
                }
            }
        }
        
        super.tableView?.backgroundColor = UIColor.blackColor()
        super.tableView?.separatorColor = PoggyConstants.POGGY_BLUE
        super.tableView?.tintColor = PoggyConstants.POGGY_BLUE
    }
    
    //MARK: Api Calls
    
    func getPublicChannels() {
        if let token = teamToken {
            dispatch_group_enter(apiDispatchGroup)
            SlackHelper.instance.getChannels(token, type: .PUBLIC, callback: { (data) in
                self.publicChannels = data
                dispatch_group_leave(self.apiDispatchGroup)
            })
        }
    }
    
    func getPrivateChannels() {
        if let token = teamToken {
            dispatch_group_enter(apiDispatchGroup)
            SlackHelper.instance.getChannels(token, type: .PRIVATE, callback: { (data) in
                self.privateChannels = data
                dispatch_group_leave(self.apiDispatchGroup)
            })
        }
    }
    
    func getUsers() {
        if let token = teamToken {
            dispatch_group_enter(apiDispatchGroup)
            SlackHelper.instance.getUsers(token, callback: { (data) in
                self.users = data
                dispatch_group_leave(self.apiDispatchGroup)
            })
        }
    }
}
