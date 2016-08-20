//
//  ViewController.swift
//  Poggy
//
//  Created by Francesco Pretelli on 24/04/16.
//  Copyright © 2016 Francesco Pretelli. All rights reserved.
//

import UIKit
import WatchConnectivity

class ActionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WCSessionDelegate  {

    @IBOutlet weak var noActionsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addNewActionButton: UIButton!
    var actions = [PoggyAction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Poggy"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        readActions()
        
        if (WCSession.isSupported()) {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        } else {
            NSLog("WCSession not supported")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.newActionHasBeenAdded(_:)), name: PoggyConstants.NEW_ACTION_CREATED, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        title = ""
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = "Poggy"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addNewActionButton.layer.cornerRadius = addNewActionButton.frame.width / 2
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: WCSessionDelegate functions
    
    func sessionDidBecomeInactive(session: WCSession) {
    
    }
    
    func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        
    }
    
    func sessionDidDeactivate(session: WCSession) {
    
    }
    
    //MARK: Actions functions
    
    func readActions() {
        if let readActions = ActionsHelper.instance.getActions() {
            actions = readActions
            tableView.reloadData()
        }
        
        if actions.count > 0 {
            noActionsLabel.hidden = true
        } else {
            noActionsLabel.hidden = false
        }
    }
    
    func saveActions() {
        ActionsHelper.instance.setActions(actions)
        updateActions()
    }
    
    func clearActiveAction(){
        let activeActions = actions.filter {$0.isActive!}
        for action in activeActions {
            action.isActive = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditSmsActionSegue" {
            if let destination = segue.destinationViewController as? SingleActionViewController {                
                if let action = sender as? SmsAction {
                    destination.updateFromActionsViewController(action)
                }
            }
        }
    }
    
    func syncActionsWithWatch(){
        do {
            var actionsDict = [String : AnyObject]()
            actionsDict[PoggyConstants.ACTIONS_DICT_ID] = NSKeyedArchiver.archivedDataWithRootObject(actions)
            try WCSession.defaultSession().updateApplicationContext(actionsDict)
        } catch {
            NSLog("Error Syncing actions with watch: \(error)")
        }
    }
    
    func newActionHasBeenAdded(notification: NSNotification) {
        updateActions()
    }
    
    func updateActions() {
        readActions()
        tableView.reloadData()
        syncActionsWithWatch()
    }
    
    //MARK: TableView Delegate Functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("ActionCell", forIndexPath: indexPath) as! ActionCell
        cell.updateData(actions[indexPath.row])
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .Destructive, title: NSLocalizedString("Delete", comment: "")) { (action, indexPath) in
            self.actions.removeAtIndex(indexPath.row)
            if self.actions.count > 0 {
                let active = self.actions.filter { $0.isActive! }.first
                if active == nil {
                    self.actions[0].isActive = true
                }
            }
            self.saveActions()
        }
        
        let edit = UITableViewRowAction(style: .Normal, title: NSLocalizedString("Edit", comment: "")) { (action, indexPath) in
            let action = self.actions[indexPath.row]
            action.actionIndex = indexPath.row
            self.performSegueWithIdentifier("EditSmsActionSegue", sender: action)
        }
        
        edit.backgroundColor = PoggyConstants.POGGY_BLUE
        return [delete, edit]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        clearActiveAction()
        actions[indexPath.row].isActive = true
        saveActions()
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

