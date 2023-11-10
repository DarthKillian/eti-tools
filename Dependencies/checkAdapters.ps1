# Get all physiscal adpaters
# Now iterate through them and only get the adapters that are up then assign them to the adapter select box

function checkAdapters () {
    # Clear the listbox to make sure nothing funky exists before enumerating our items
    $selectAdapter.Items.Clear()
    foreach ($adapter in Get-NetAdapter -Physical) {
       if ($adapter.status -eq "Up") {
          $adapter | ForEach-Object { $selectAdapter.Items.Add($_.Name) } | Out-Null
       }
    }
 
    # Select the first adapter in the list and focus it
    $selectAdapter.SelectedIndex = 0
    $selectAdapter.Focus() | Out-Null
 }