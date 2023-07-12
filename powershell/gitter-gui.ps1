Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = 'SilentlyContinue'
$gitterFolderPath = "$env:userprofile\.gitter"
$projectsFilePath = "$gitterFolderPath\projects.json"
Invoke-Expression "git config --global core.safecrlf false"

if (-not (Test-Path -Path $gitterFolderPath -PathType Container)) {
    New-Item -Path $gitterFolderPath -ItemType Directory | Out-Null
}

if (-not (Test-Path -Path $projectsFilePath -PathType Leaf)) {
    @"
{
   "deleteMe": {
      "path": "S:\\OneDrive\\fake"
   }
}
"@ | Set-Content -Path $projectsFilePath
}

function PopulateDropdown($comboBox) {
    $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
    $comboBox.Items.Clear()
    $projects.PSObject.Properties.Name | ForEach-Object {
        $comboBox.Items.Add($_)
    }
}

function DeleteButtonClick {
    $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
    $deleteForm = New-Object System.Windows.Forms.Form
    $deleteForm.Text = "Delete Project"
    $deleteForm.Width = 300
    $deleteForm.Height = 200

    $deleteLabel = New-Object System.Windows.Forms.Label
    $deleteLabel.Location = New-Object System.Drawing.Point(10, 10)
    $deleteLabel.Width = 280
    $deleteLabel.Text = "Select a project to delete:"
    $deleteForm.Controls.Add($deleteLabel)

    foreach ($project in $projects.PSObject.Properties) {
        $deleteButton = New-Object System.Windows.Forms.Button
        $deleteButton.Location = New-Object System.Drawing.Point(10, (40 + $deleteForm.Controls.Count * 30))
        $deleteButton.Width = 150
        $deleteButton.Text = $project.Name
        $deleteButton.Tag = $project.Name
        $deleteButton.Add_Click({ DeleteProject $args[0].Tag })

        $deleteForm.Controls.Add($deleteButton)
    }

    $deleteForm.ShowDialog() | Out-Null
}

function ClearButtonClick {
    Remove-Item $projectsFilePath
    PopulateDropdown $dropdownBox
    [System.Windows.Forms.MessageBox]::Show("All projects have been cleared.", "Project List Cleared", "OK", "Information")
}

function DeleteProject($projectName) {
    $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
    $projects.PSObject.Properties.Remove($projectName)
    $projects | ConvertTo-Json | Set-Content -Path $projectsFilePath

    PopulateDropdown $dropdownBox

    [System.Windows.Forms.MessageBox]::Show("Project '$projectName' has been removed.", "Project Remove", "OK", "Information")
    $deleteForm.Close()
}

function DropdownSelectionChanged {
    $selectedProject = $dropdownBox.SelectedItem.ToString()
    $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
    $projectPath = $projects.$selectedProject.path
    $selectedProjectLabel.Text = "$projectPath"
}

function NewProjectButtonClick {
    if (-not (Test-Path -Path $gitterFolderPath -PathType Container)) {
    New-Item -Path $gitterFolderPath -ItemType Directory | Out-Null
}

if (-not (Test-Path -Path $projectsFilePath -PathType Leaf)) {
    @"
{
   "deleteMe": {
      "path": "S:\\OneDrive\\fake"
   }
}
"@ | Set-Content -Path $projectsFilePath
}
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $result = $folderBrowser.ShowDialog()

    if ($result -eq 'OK') {
        $projectPath = $folderBrowser.SelectedPath
        $projectName = Split-Path -Leaf $projectPath

        if (!(Test-Path -Path "$projectPath\.git" -PathType Container)) {
            [System.Windows.Forms.MessageBox]::Show("The selected folder is not a Git repository.", "Invalid Git Repository", "OK", "Error")
            return
        }

        $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
        $projects | Add-Member -NotePropertyName $projectName -NotePropertyValue @{ "path" = $projectPath } -Force
        $projects | ConvertTo-Json | Set-Content -Path $projectsFilePath

        PopulateDropdown $dropdownBox
    }
}

function CommitButtonClick {
    $selectedProject = $dropdownBox.SelectedItem.ToString()
    $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
    $projectPath = $projects.$selectedProject.path
    $commitMessage = $commitTextBox.Text

    $output = (Invoke-Expression "cd '$projectPath'; git.exe add .; git.exe commit -m '$commitMessage'; git.exe push --quiet --no-progress") | Out-String
    $outputTextBox.Text = $output
}

function PullButtonClick {
    $selectedProject = $dropdownBox.SelectedItem.ToString()
    $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
    $projectPath = $projects.$selectedProject.path

    $output = (Invoke-Expression "cd '$projectPath'; git.exe pull --no-progress") | Out-String
    $outputTextBox.Text = $output
}

function StatusButtonClick {
    $selectedProject = $dropdownBox.SelectedItem.ToString()
    $projects = Get-Content -Raw -Path $projectsFilePath | ConvertFrom-Json
    $projectPath = $projects.$selectedProject.path

    $output = (Invoke-Expression "cd '$projectPath'; git.exe status") | Out-String
    $outputTextBox.Text = $output
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "[gitter] [v0.4] [©2023 b3b0]"
$form.Width = 450
$form.Height = 390
$form.FormBorderStyle = 'FixedDialog'

$dropdownBox = New-Object System.Windows.Forms.ComboBox
$dropdownBox.Location = New-Object System.Drawing.Point(10, 10)
$dropdownBox.Width = 420
$dropdownBox.Add_SelectedIndexChanged({ DropdownSelectionChanged })

$newProjectButton = New-Object System.Windows.Forms.Button
$newProjectButton.Location = New-Object System.Drawing.Point(10, 60)
$newProjectButton.Width = 100
$newProjectButton.Text = "Add Project"
$newProjectButton.Add_Click({ NewProjectButtonClick })

$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Location = New-Object System.Drawing.Point(160, 60)
$deleteButton.Width = 120
$deleteButton.Text = "Remove Project"
$deleteButton.Add_Click({ DeleteButtonClick })

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Point(310, 60)
$clearButton.Width = 120
$clearButton.Text = "Clear Projects"
$clearButton.Add_Click({ ClearButtonClick })

$selectedProjectLabel = New-Object System.Windows.Forms.Label
$selectedProjectLabel.Location = New-Object System.Drawing.Point(10, 35)
$selectedProjectLabel.Width = 300

$commitLabel = New-Object System.Windows.Forms.Label
$commitLabel.Location = New-Object System.Drawing.Point(10, 90)
$commitLabel.Width = 380
$commitLabel.Text = "Commit Message:"

$commitTextBox = New-Object System.Windows.Forms.TextBox
$commitTextBox.Location = New-Object System.Drawing.Point(10, 115)
$commitTextBox.Width = 420

$commitButton = New-Object System.Windows.Forms.Button
$commitButton.Location = New-Object System.Drawing.Point(10, 145)
$commitButton.Width = 100
$commitButton.Text = "Commit"
$commitButton.Add_Click({ CommitButtonClick })

$pullButton = New-Object System.Windows.Forms.Button
$pullButton.Location = New-Object System.Drawing.Point(160, 145)
$pullButton.Width = 80
$pullButton.Text = "Pull"
$pullButton.Add_Click({ PullButtonClick })

$statusButton = New-Object System.Windows.Forms.Button
$statusButton.Location = New-Object System.Drawing.Point(310, 145)
$statusButton.Width = 80
$statusButton.Text = "Status"
$statusButton.Add_Click({ StatusButtonClick })

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 180)
$outputTextBox.Width = 420
$outputTextBox.Height = 150
$outputTextBox.Multiline = $true
$outputTextBox.ReadOnly = $true

$form.Controls.Add($dropdownBox)
$form.Controls.Add($selectedProjectLabel)
$form.Controls.Add($commitLabel)
$form.Controls.Add($commitTextBox)
$form.Controls.Add($commitButton)
$form.Controls.Add($pullButton)
$form.Controls.Add($outputTextBox)
$form.Controls.Add($newProjectButton)
$form.Controls.Add($deleteButton)
$form.Controls.Add($clearButton)
$form.Controls.Add($statusButton)
PopulateDropdown $dropdownBox
$form.ShowDialog() | Out-Null
