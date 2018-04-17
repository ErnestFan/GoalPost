//
//  GoalsVC.swift
//  goalpost
//
//  Created by Ernest Fan on 2018-04-13.
//  Copyright © 2018 ERF. All rights reserved.
//

import UIKit
import CoreData

let appDelegate = UIApplication.shared.delegate as? AppDelegate

class GoalsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var undoViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var undoView: UIView!
    @IBOutlet weak var undoButton: UIButton!
    
    var goals: [Goal] = []
    var undoViewAnimateId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCoreDataObjects()
        tableView.reloadData()
    }
    
    func fetchCoreDataObjects() {
        self.fetch { (complete) in
            if complete {
                if goals.count > 0 {
                    tableView.isHidden = false
                    tableView.reloadData()
                } else {
                    tableView.isHidden = true
                }
            }
        }
    }
    
    func undoViewShow() {
        undoView.isHidden = false
        
        UIView.animate(withDuration: 0.3, delay: 0.5, options: .allowUserInteraction, animations: {
            self.undoView.alpha = 1.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func undoViewHide(_ id: String, in time: Double) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            if self.undoViewAnimateId == id {
                UIView.animate(withDuration: 0.3, delay: 0, options: .allowUserInteraction, animations: {
                    self.undoView.alpha = 0.01
                    self.view.layoutIfNeeded()
                }) { (finish) in
                    if finish {
                        self.undoView.isHidden = true
                    }
                }
            }
        }
    }

    @IBAction func addGoalBtnWasPressed(_ sender: Any) {
        guard let createGoalVC = storyboard?.instantiateViewController(withIdentifier: "CreateGoalVC") else { return }
        presentDetail(createGoalVC)
    }
    
    @IBAction func undoBtnWasPressed(_ sender: Any) {
        undoDeleteGoal()
        fetchCoreDataObjects()
        self.undoViewAnimateId = ""
        self.undoViewHide("", in: 0.5)
    }
}

extension GoalsVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "goalCell") as? GoalCell else { return UITableViewCell() }
        let goal = goals[indexPath.row]
        cell.configureCell(goal: goal)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "DELETE") { (rowAction, indexPath) in
            tableView.beginUpdates()
            self.removeGoal(atIndexPath: indexPath)
            self.fetchCoreDataObjects()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
        
        let addAction = UITableViewRowAction(style: .normal, title: "ADD 1") { (rowAction, indexPath) in
            tableView.beginUpdates()
            self.setProgress(atIndexPath: indexPath)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
        
        deleteAction.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        addAction.backgroundColor = #colorLiteral(red: 0.9385011792, green: 0.7164435983, blue: 0.3331357837, alpha: 1)
        
        return [deleteAction, addAction]
    }
}

extension GoalsVC {
    func undoDeleteGoal() {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else { return }
        
        managedContext.undoManager?.undo()
    }
    
    func setProgress(atIndexPath indexPath: IndexPath) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else { return }
        
        let chosenGoal = goals[indexPath.row]
        
        if chosenGoal.goalProgress < chosenGoal.goalCompletionValue {
            chosenGoal.goalProgress = chosenGoal.goalProgress + 1
        } else {
            return
        }
        
        do {
            try managedContext.save()
        } catch {
            debugPrint("Could not set progress: \(error.localizedDescription)")
        }
    }
    
    func removeGoal(atIndexPath indexPath: IndexPath) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else { return }
        
        managedContext.undoManager = UndoManager()
        
        let key = goals[indexPath.row].goalDescription
        
        managedContext.delete(goals[indexPath.row])
        
        do {
            try managedContext.save()
            self.undoViewAnimateId = key!
            self.undoViewShow()
            self.undoViewHide(key!, in: 4.0)
        } catch {
            debugPrint("Could not remove: \(error.localizedDescription)")
        }
        
    }
    
    func fetch(completion: (_ complete: Bool) -> ()) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else { return }
        
        let fetchRequest = NSFetchRequest<Goal>(entityName: "Goal")
        
        do {
            goals = try managedContext.fetch(fetchRequest)
            completion(true)
        } catch {
            debugPrint("Could not fetch: \(error.localizedDescription)")
            completion(false)
        }
    }
}








