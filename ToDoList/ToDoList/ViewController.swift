//
//  ViewController.swift
//  ToDoList
//
//  Created by Jem1s on 22.09.2024.
//

import UIKit
import CoreData



class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var addTaskButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todayDate: UILabel!

    // MARK: - Properties
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var tasks: [TaskModel] = [] // Массив для хранения задач
    private var models = [ToDoListItem]()

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
        setupLongPressGesture()
        setTodayDate()
    }

    // MARK: - UI Setup
    private func setupUI() {
        addTaskButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        //tableView.register(UITableViewCell(style: .subtitle, reuseIdentifier: "cell"))
        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - Date Setup
    private func setTodayDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d" // Формат: день недели, месяц число
        let today = Date()
        todayDate.text = dateFormatter.string(from: today) // Устанавливаем отформатированную дату в UILabel
    }

    // MARK: - Data Loading
    private func loadInitialData() {
        if !UserDefaults.standard.bool(forKey: "hasFetchedTasks") {
            fetchTasksFromNetwork()
        } else {
            getAllItems()
        }
    }

    // MARK: - Network Fetching
    private func fetchTasksFromNetwork() {
        let networkService = NetworkService()
        networkService.fetchTasks { [weak self] fetchedTasks in
            guard let self = self else { return }
            if let fetchedTasks = fetchedTasks {
                self.tasks = fetchedTasks // Сохраняем полученные задачи
                self.addTasksToCoreData(fetchedTasks: fetchedTasks)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                UserDefaults.standard.set(true, forKey: "hasFetchedTasks") // Устанавливаем флаг в UserDefaults
            }
        }
    }

   // MARK: - Core Data Operations

   private func addTasksToCoreData(fetchedTasks: [TaskModel]) {
       for task in fetchedTasks {
           createItem(name: task.todo ?? "Задачи не найдены") // добавление полученных задач из API
       }
   }

   private func getAllItems() {
       let fetchRequest: NSFetchRequest<ToDoListItem> = ToDoListItem.fetchRequest()

       // Сортируем по дате создания (предполагаем, что у вас есть поле createAt)
       fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createAt", ascending: false)]

       do {
           models = try context.fetch(fetchRequest)
           DispatchQueue.main.async {
               self.tableView.reloadData()
           }
       } catch {
           print("Ошибка при получении задач из Core Data: \(error)")
       }
   }

   private func createItem(name: String) {
       let newItem = ToDoListItem(context: context)
       newItem.name = name
       newItem.createAt = Date()

       do {
           try context.save() // Сохраняем новую задачу в Core Data

           // Добавляем новый элемент в начало массива models
           models.insert(newItem, at: 0)
           tableView.reloadData() // Обновляем таблицу
       } catch {
           print("Ошибка при сохранении новой задачи: \(error)")
       }
   }

   private func updateItem(item: ToDoListItem, newName: String) {
       item.name = newName

       do {
           try context.save() // Сохраняем изменения в Core Data

           if let index = models.firstIndex(of:item) {
               models[index].name=newName
               tableView.reloadRows(at:[IndexPath(row:index, section : 0)],with:.automatic)
           }
       } catch {
           print("Ошибка при обновлении задачи: \(error)")
       }
   }

   private func deleteItem(item : ToDoListItem){
      context.delete(item)

      do{
          try context.save()

          if let index=models.firstIndex(of:item){
              models.remove(at:index)
              tableView.deleteRows(at:[IndexPath(row:index , section : 0)],with:.automatic)
          }
      }catch{
          print("Ошибка при удалении задачи : \(error)")
      }
   }

   // MARK:- Button Actions

   @objc private func didTapAdd() {
       let alert = UIAlertController(title:"Новая задача", message:"Добавить новую задачу в список", preferredStyle:.alert)

       alert.addTextField(configurationHandler:nil)

       alert.addAction(UIAlertAction(title:"Принять", style:.default, handler:{[weak self] _ in
           guard let self=self,
                 let field=alert.textFields?.first,
                 let text=field.text,!text.isEmpty else { return }

           self.createItem(name:text)
       }))
       
       alert.addAction(UIAlertAction(title:"Отмена", style:.cancel))

       present(alert, animated:true)
   }

   // MARK:- Gesture Handling

   private func setupLongPressGesture() {
       let longPressGesture = UILongPressGestureRecognizer(target:self, action:#selector(handleLongPress(_:)))
       tableView.addGestureRecognizer(longPressGesture)
   }

   @objc private func handleLongPress(_ gesture:UILongPressGestureRecognizer) {
       if gesture.state == .began{
           let location=gesture.location(in:self.tableView)
           if let indexPath=self.tableView.indexPathForRow(at : location){
               let item=models[indexPath.row]
               presentEditAlert(for:item , at:indexPath)
           }
       }
   }

   private func presentEditAlert(for item : ToDoListItem , at indexPath : IndexPath){
     let alert=UIAlertController(title:"Редактировать задачу", message:"Введите вашу задачу", preferredStyle:.alert)

     alert.addTextField { textField in
         textField.text=item.name
     }

     alert.addAction(UIAlertAction(title:"Сохранить", style:.default, handler:{[weak self] _ in
         guard let self=self,
               let field=alert.textFields?.first,
               let newName=field.text,!newName.isEmpty else { return }

         self.updateItem(item:item,newName:newName)

         if let index=self.models.firstIndex(of:item){
             self.models[index].name=newName
             self.tableView.reloadRows(at:[IndexPath(row:index , section : 0)],with:.automatic)
         }
     }))
     
     alert.addAction(UIAlertAction(title:"Удалить", style:.destructive, handler:{[weak self] _ in
         guard let self=self else { return }
         self.deleteItem(item:item)
     }))
     
     alert.addAction(UIAlertAction(title:"Отмена", style:.cancel))

     present(alert , animated:true)
   }

   //MARK: - Table View Data Source Methods

   func tableView(_ tableView:UITableView , numberOfRowsInSection section:Int)-> Int{
      return models.count
   }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Устанавливаем название задачи
        cell.textLabel?.text = model.name
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20) // Увеличиваем размер шрифта для названия задачи

        // Форматируем дату
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE - HH:mm" // Формат даты и времени
        let dateString = dateFormatter.string(from: model.createAt ?? Date())

        // Устанавливаем дату в detailTextLabel
        cell.detailTextLabel?.text = dateString
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16) // Устанавливаем размер шрифта для даты
        cell.detailTextLabel?.textColor = UIColor.black.withAlphaComponent(0.5) // Устанавливаем цвет текста

        cell.textLabel?.numberOfLines = 0 // Позволяем многострочный текст
        cell.detailTextLabel?.numberOfLines = 0 // Позволяем многострочный текст для даты
        
        cell.accessoryType = model.isCompleted ? .checkmark : .none

        return cell
    }

   func tableView(_ tableView:UITableView , didSelectRowAt indexPath : IndexPath){
      tableView.deselectRow(at:indexPath , animated:true )
      let item = models[indexPath.row]
      
      item.isCompleted.toggle()

      do{
          try context.save()
      }catch{
          print("Ошибка при сохранении состояния выполнения : \(error)")
      }

      tableView.reloadRows(at:[indexPath],with:.automatic )
  }
}
