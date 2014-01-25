//
//  TodoTableViewController.m
//  TodoApp
//
//  Created by Ruchi Varshney on 1/23/14.
//  Copyright (c) 2014 Ruchi Varshney. All rights reserved.
//

#import <Parse/Parse.h>
#import "Toast+UIView.h"

#import "NSMutableArray+Move.h"

#import "TodoTableViewController.h"
#import "TodoCell.h"

@interface TodoTableViewController ()

@property (nonatomic, strong) NSMutableArray *todos;
- (IBAction)onAddButtonItem:(id)sender;

@end

@implementation TodoTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Todos";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self loadTodos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.todos.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *text = self.todos[indexPath.row][@"text"];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:14.0], NSFontAttributeName, nil];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    CGSize constraint = CGSizeMake(250 - 8, CGFLOAT_MAX);
    CGSize size = [attributedString boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
    return MAX(size.height + 20 + 16, 44);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TodoCell";
    TodoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.todoTextView.delegate = self;
    cell.todoTextView.tag = indexPath.row;
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:14.0], NSFontAttributeName, nil];
    cell.todoTextView.attributedText = [[NSAttributedString alloc] initWithString:@" " attributes:attributes];
    cell.accessoryType = UITableViewCellAccessoryNone;

    // If the task is done, add strikethrough and checkmark
    PFObject *todo = [self.todos objectAtIndex:indexPath.row];
    if (todo[@"done"] == [NSNumber numberWithBool:YES]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:14.0], NSFontAttributeName, [NSNumber numberWithInt:1], NSStrikethroughStyleAttributeName, nil];
    }

    cell.todoTextView.attributedText = [[NSAttributedString alloc] initWithString:todo[@"text"] attributes:attributes];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.todos moveObjectFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
    [self updateTodoPositions:fromIndexPath.row toIndex:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete from Parse
        PFObject *deleteTodo = [self.todos objectAtIndex:indexPath.row];
        [deleteTodo deleteInBackground];

        // Delete from view
        [self.todos removeObjectAtIndex:indexPath.row];
        [self updateTodoPositions:indexPath.row toIndex:self.todos.count - 1];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

        [self saveTodos];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self onAddButtonItem:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Toggle the done state
    PFObject *selectTodo = self.todos[indexPath.row];
    NSNumber *done = selectTodo[@"done"];
    selectTodo[@"done"] = [NSNumber numberWithBool:![done boolValue]];
    [selectTodo saveInBackground];
    [self.tableView reloadData];
    [self saveTodos];
}

- (void)loadTodos
{
    // First load items from NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedTodos = [defaults objectForKey:@"todos"];
    if (savedTodos == nil) {
        self.todos = [[NSMutableArray alloc] init];
    } else {
        self.todos= [NSMutableArray arrayWithArray:savedTodos];
    }

    // Load the table
    [self.tableView reloadData];

    // Sync with Parse
    PFQuery *query = [PFQuery queryWithClassName:@"Todo"];
    [query orderByAscending:@"position"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [self.navigationController.view makeToast:[error localizedDescription] duration:2.0 position:@"bottom"];
        }
        [self.todos removeAllObjects];
        [self.todos addObjectsFromArray:objects];
        [self.tableView reloadData];
        [self.navigationController.view makeToast:@"Synced" duration:2.0 position:@"bottom"];

        // Update NSUserDefaults with the data from Parse
        // The data from Parse is considered most accurate,
        // considering there could be other devices with the app
        [self saveTodos];
    }];
}

- (void)saveTodos
{
    // Save to NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *serializable = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < self.todos.count; i++) {
        NSMutableDictionary *object = [[NSMutableDictionary alloc] init];
        [object setValue:self.todos[i][@"text"] forKey:@"text"];
        [object setValue:self.todos[i][@"done"] forKey:@"done"];
        [object setValue:self.todos[i][@"position"] forKey:@"position"];
        [serializable addObject:[NSDictionary dictionaryWithDictionary:object]];
    }
    [defaults setObject:[NSArray arrayWithArray:serializable] forKey:@"todos"];
    [defaults synchronize];
}

- (void)updateTodoPositions:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    int min = MIN(fromIndex, toIndex);
    int max = MAX(fromIndex, toIndex);
    for (NSUInteger i = min; i <=max && i < self.todos.count; i++) {
        PFObject *todo = [self.todos objectAtIndex:i];
        todo[@"position"] = [NSNumber numberWithInt:i];
        [todo saveInBackground];
    }
    [self saveTodos];
}

- (IBAction)onAddButtonItem:(id)sender
{
    PFObject *newTodo = [PFObject objectWithClassName:@"Todo"];
    newTodo[@"text"] = @"";
    newTodo[@"done"] = [NSNumber numberWithBool:NO];
    newTodo[@"position"] = [NSNumber numberWithInt:0];
    [newTodo saveInBackground];
    
    [self.todos insertObject:newTodo atIndex:0];
    [self updateTodoPositions:1 toIndex:self.todos.count - 1];
    [self.tableView reloadData];

    // Set the cursor focus on the added item
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    TodoCell *cell = (TodoCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.todoTextView becomeFirstResponder];

    [self saveTodos];
}

#pragma mark - Text view delegate methods

- (void)textViewDidChange:(UITextView *)textView
{
    // Sync back text field updates
    PFObject *todo = self.todos[textView.tag];
    todo[@"text"] = textView.text;
    [todo saveInBackground];
    [self saveTodos];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Trigger size updates
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

    // Dismiss keyboard on enter
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

@end
