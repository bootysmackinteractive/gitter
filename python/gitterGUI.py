import os
import json
import tkinter as tk
from tkinter import messagebox, ttk, filedialog

gitter_folder_path = os.path.expanduser("~/.gitter")
projects_file_path = os.path.join(gitter_folder_path, "projects.json")

def populate_dropdown():
    projects = []
    if os.path.exists(projects_file_path):
        with open(projects_file_path, "r") as file:
            projects = json.load(file)

    dropdown_box["values"] = list(projects.keys())

def delete_button_click():
    projects = {}
    if os.path.exists(projects_file_path):
        with open(projects_file_path, "r") as file:
            projects = json.load(file)

    selected_project = dropdown_box.get()
    if selected_project in projects:
        del projects[selected_project]

    with open(projects_file_path, "w") as file:
        json.dump(projects, file)

    populate_dropdown()
    messagebox.showinfo("Project Remove", f"Project '{selected_project}' has been removed.")

def clear_button_click():
    if os.path.exists(projects_file_path):
        os.remove(projects_file_path)

    populate_dropdown()
    messagebox.showinfo("Project List Cleared", "All projects have been cleared.")

def new_project_button_click():
    folder_path = filedialog.askdirectory()
    if folder_path:
        project_name = os.path.basename(folder_path)

        if not os.path.isdir(os.path.join(folder_path, ".git")):
            messagebox.showerror("Invalid Git Repository", "The selected folder is not a Git repository.")
            return

        projects = {}
        if os.path.exists(projects_file_path):
            with open(projects_file_path, "r") as file:
                projects = json.load(file)

        projects[project_name] = {"path": folder_path}

        with open(projects_file_path, "w") as file:
            json.dump(projects, file)

        populate_dropdown()

def dropdown_selection_changed(event):
    selected_project = dropdown_box.get()
    if selected_project:
        projects = {}
        if os.path.exists(projects_file_path):
            with open(projects_file_path, "r") as file:
                projects = json.load(file)

        project_path = projects.get(selected_project, {}).get("path", "")
        selected_project_label["text"] = project_path

def commit_button_click():
    selected_project = dropdown_box.get()
    projects = {}
    if os.path.exists(projects_file_path):
        with open(projects_file_path, "r") as file:
            projects = json.load(file)

    project_path = projects.get(selected_project, {}).get("path", "")
    commit_message = commit_textbox.get()

    if project_path:
        os.chdir(project_path)
        command = f'git add . && git commit -m "{commit_message}" && git push'
        output = os.popen(command).read()
        output_textbox.config(state=tk.NORMAL)
        output_textbox.insert(tk.END, output + "\n" + "-" * 25 + "\n")
        output_textbox.config(state=tk.DISABLED)

def pull_button_click():
    selected_project = dropdown_box.get()
    projects = {}
    if os.path.exists(projects_file_path):
        with open(projects_file_path, "r") as file:
            projects = json.load(file)

    project_path = projects.get(selected_project, {}).get("path", "")

    if project_path:
        os.chdir(project_path)
        output = os.popen("git pull").read()
        output_textbox.config(state=tk.NORMAL)
        output_textbox.insert(tk.END, output + "\n" + "-" * 25 + "\n")
        output_textbox.config(state=tk.DISABLED)

def status_button_click():
    selected_project = dropdown_box.get()
    projects = {}
    if os.path.exists(projects_file_path):
        with open(projects_file_path, "r") as file:
            projects = json.load(file)

    project_path = projects.get(selected_project, {}).get("path", "")

    if project_path:
        os.chdir(project_path)
        output = os.popen("git status").read()
        output_textbox.config(state=tk.NORMAL)
        output_textbox.insert(tk.END, output + "\n" + "-" * 25 + "\n")
        output_textbox.config(state=tk.DISABLED)


root = tk.Tk()
root.title("[gitter] [v0.4] [©2023 b3b0]")
root.geometry("450x390")
root.resizable(False, False)

dropdown_box = ttk.Combobox(root, width=41)
dropdown_box.place(x=10, y=10)
dropdown_box.bind("<<ComboboxSelected>>", dropdown_selection_changed)

selected_project_label = ttk.Label(root, width=40)
selected_project_label.place(x=10, y=35)

commit_label = ttk.Label(root, text="Commit Message:", width=38)
commit_label.place(x=10, y=90)

commit_textbox = ttk.Entry(root, width=42)
commit_textbox.place(x=10, y=115)

commit_button = ttk.Button(root, text="Commit", width=10, command=commit_button_click)
commit_button.place(x=10, y=145)

pull_button = ttk.Button(root, text="Pull", width=8, command=pull_button_click)
pull_button.place(x=160, y=145)

status_button = ttk.Button(root, text="Status", width=8, command=status_button_click)
status_button.place(x=310, y=145)

output_textbox = tk.Text(root, width=52, height=9, font=("Courier New", 9))
output_textbox.place(x=10, y=180)

scrollbar = ttk.Scrollbar(root, command=output_textbox.yview)
scrollbar.place(x=421, y=180, height=150)
output_textbox.config(yscrollcommand=scrollbar.set)

new_project_button = ttk.Button(root, text="Add Project", width=12, command=new_project_button_click)
new_project_button.place(x=10, y=60)

delete_button = ttk.Button(root, text="Remove Project", width=14, command=delete_button_click)
delete_button.place(x=160, y=60)

clear_button = ttk.Button(root, text="Clear Projects", width=14, command=clear_button_click)
clear_button.place(x=310, y=60)

populate_dropdown()

root.mainloop()
